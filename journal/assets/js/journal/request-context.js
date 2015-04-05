/** 
 * OpenBD Journaling Tool
 * Copyright (C) 2015
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @version $Id: request-context.js 2522 2015-02-19 23:14:55Z wpultz $
 * @authow wpultz
 * @class journal.request-context
 * @param {String} _journalFile Name of the journal file to track, should not include any portion of file path
 */
function RequestContext( _journalFile ) {

	var fileName = _journalFile,
		isPlaying = false,
		busy = false,
		journalLen,
		interval,
		entryIndex = 0,
		lines = [],
		sessionsCache = {},
		// TODO - many of these numbers could be specified with options
		speed = 5, // in lines per second
		maxSpeed = 10,
		minSpeed = 1,
		lineBufferSize = 200,
		loadThreshold = 100,
		maxEntries = 1000;


	/**
	 * @private
	 * @method loadLines
	 * @param {String} _direction prepend|append. dictates whether the lines will be appended to the end of the lines array or preprended
	 */
	var loadLines = function( _direction ) {
		// if waiting on a load of journal lines, return false to as not to pollute the natural order of lines
		if ( busy ) {
			return false;
		}
		busy = true;

		// build up arguments for the endpoint to get journal lines
		var args = {};
		args._journalFile = fileName;

		// add the _start and _stop arguments, based upon which direction we are going
		if ( !lines.length ) {
			args._start = 0;
			args._stop = lineBufferSize;
		} else if ( _direction === 'prepend' ) {
			args._start = lines[ 0 ].journalid - lineBufferSize;
			args._stop = lines[ 0 ].journalid;
		} else if ( _direction === 'append' ) {
			args._start = lines[ lines.length - 1 ].journalid + 1;
			args._stop = lines[ lines.length - 1 ].journalid + lineBufferSize;
		}

		// don't go too far
		if ( args._stop <= 0 ) {
			busy = false;
			return false;
		}

		// remote call to get the journal entry lines
		$.ajax( {
			url: 'journal/journal_cache.cfc?METHOD=getJournalEntries',
			type: 'POST',
			dataType: 'JSON',
			data: args,
			success: function( _resp ) {
				// merge the sessions
				if ( _resp.sessions ) {
					for ( var sess in _resp.sessions ) {
						if ( _resp.sessions.hasOwnProperty( sess ) ) {
							sessionsCache[ sess ] = _resp.sessions[ sess ];
						}
					}
				}
				if ( _direction === 'prepend' ) {
					lines = _resp.entries.concat( lines );
					entryIndex += _resp.entries.length;
					if ( lines.length > maxEntries ) {
						//lines = lines.slice( 0, maxEntries );
					}
				} else if ( _direction === 'append' ) {
					lines = lines.concat( _resp.entries );
					var oldLen = lines.length;
					if ( lines.length > maxEntries && entryIndex > ( oldLen - maxEntries ) ) {
						// too many entries, trim down the array of entries to keep from growing out of control, and adjust the entry index accordingly
						lines = lines.slice( -maxEntries );
						entryIndex -= ( oldLen - lines.length );
					}
				}
				if ( _resp.journallen ) {
					journalLen = _resp.journallen;
				}
			},
			error: function( a, b, c ) {
				alert( 'an error has occurred, and journal data was not loaded' );
				pause();
			},
			complete: function() {
				busy = false;
			}
		} );
	};


	/**
	 * sets interval to call stepLine for the specified number of lines per second
	 * @method play
	 */
	var play = function() {
		if ( !isPlaying ) {
			isPlaying = true;
			interval = setInterval( function() {
				// if the index in the journal lines array has been surpassed, pause the playback
				if ( entryIndex >= lines.length && lines.length > 0 ) {
					pause();
					return false;
				}
				stepLine();
			}, ( 1000 / speed ) );
		}
	};


	/** 
	 * clears the interval set by the play function, pausing the playback
	 * @method pause
	 */
	var pause = function() {
		isPlaying = false;
		if ( interval ) {
			clearInterval( interval );
		}
	};


	/** 
	 * @method setPlaybackSpeep
	 * @param {numeric} _speed number of lines to iterate over per second
	 */
	var setPlaybackSpeed = function( _speed ) {
		if ( _speed > maxSpeed ) {
			speed = maxSpeed;
		} else if ( _speed < minSpeed ) {
			speed = minSpeed;
		} else {
			speed = _speed;
		}
		// stop/start to pick up the new speed in the interval
		if ( isPlaying ) {
			pause();
			play();
		}
	};


	/** 
	 * triggers an event on the document to indicate that the context has moved forward, containing current file, file line, elapsed time, and journal line data
	 * increments the entryIndex counter
	 * @method stepLine
	 */
	var stepLine = function() {
		normalizeEntryIndex();
		// load more lines if the entryIndex has crossed the loadThreshold
		if ( !lines.length || ( lines[ entryIndex ].journalid > lines[ lines.length - 1 ].journalid - loadThreshold ) ) {
			loadLines( 'append' );
		}

		if ( lines.length ) {
			var eArgs = {
				currentJournalLine: lines[ entryIndex ].journalid,
				currentFileId: lines[ entryIndex ].file_id,
				currentLineNum: lines[ entryIndex ].line,
				elapsedTime: lines[ entryIndex ].t_offset
			};
			if ( lines[ entryIndex ].session && sessionsCache[ lines[ entryIndex ].session ] ) {
				eArgs.session = sessionsCache[ lines[ entryIndex ].session ];
			}
			$( document ).trigger( 'perf:stepforward', eArgs );
			entryIndex++;
		}
	};


	/** 
	 * triggers an event on the document to indicate that the context has moved backward, containing current file, file line, elapsed time, and journal line data.
	 * decrements the entryIndex counter
	 * @method stepLineBack
	 */
	var stepLineBack = function() {
		normalizeEntryIndex();
		if ( lines.length && lines[ entryIndex ].journalid <= 1 ) {
			return false;
		}
		// load more lines if the entryIndex has crossed the loadThreshold
		if ( !lines.length || ( lines[ entryIndex ].journalid < ( lines[ 0 ].journalid + loadThreshold ) ) ) {
			loadLines( 'prepend' );
		}
		if ( entryIndex && lines.length ) {
			var eArgs = {
				currentJournalLine: lines[ entryIndex ].journalid,
				currentFileId: lines[ entryIndex ].file_id,
				currentLineNum: lines[ entryIndex ].line,
				elapsedTime: lines[ entryIndex ].t_offset
			};
			if ( lines[ entryIndex ].session && sessionsCache[ lines[ entryIndex ].session ] ) {
				eArgs.session = sessionsCache[ lines[ entryIndex ].session ];
			}
			$( document ).trigger( 'perf:stepback', eArgs );
			entryIndex--;
		}
	};


	/**
	 * limits the entryIndex to the between 0 and the length of journal lines array
	 * @method normalizeEntryIndex
	 */
	var normalizeEntryIndex = function() {
		if ( entryIndex >= lines.length && lines.length > 0 ) {
			entryIndex = lines.length - 1;
			pause();
		} else if ( entryIndex < 0 ) {
			entryIndex = 0;
		}
	};


	/** 
	 * reloads the journal line array and triggers event on document with pertinent data
	 * @method gotoTimeMS
	 * @param {numeric} _ms millisecond to jump playback to
	 */
	var gotoTimeMS = function( _ms ) {
		var args = {
			_journalFile: fileName,
			_ms: _ms,
			_entryBuffer: lineBufferSize
		};
		$.ajax( {
			url: 'journal/journal_cache.cfc?METHOD=getJournalEntriesMS',
			type: 'POST',
			dataType: 'JSON',
			data: args,
			success: function( _resp ) {
				// update the session cache
				if ( _resp.sessions ) {
					for ( var sess in _resp.sessions ) {
						if ( _resp.sessions.hasOwnProperty( sess ) ) {
							sessionsCache[ sess ] = _resp.sessions[ sess ];
						}
					}
				}

				lines = _resp.entries;
				// if a real time is specified find the first line there, otherwise back to the beginning
				if ( _ms && lines.length ) {
					// not terribly efficient, but an ends to a means
					var liner = 0;
					while ( _ms >= lines[ liner ].t_offset && liner < lines.length - 1 ) {
						if ( lines[ liner ].line ) {
							entryIndex = liner;
						}
						liner++;
					}
				} else {
					entryIndex = 0;
				}

				// trigger gotoline
				var eArgs = {
					currentJournalLine: lines[ entryIndex ].journalid,
					currentFileId: lines[ entryIndex ].file_id,
					currentLineNum: lines[ entryIndex ].line,
					elapsedTime: lines[ entryIndex ].t_offset
				};
				if ( lines[ entryIndex ].session && sessionsCache[ lines[ entryIndex ].session ] ) {
					eArgs.session = sessionsCache[ lines[ entryIndex ].session ];
				}
				$( document ).trigger( 'perf:gotoline', eArgs );
			},
			error: function( a, b, c ) {
				alert( 'an error has occurred, and journal data was not loaded' );
				pause();
			}
		} );
	};


	// expose public functions
	return {
		play: play,
		pause: pause,
		stepLine: stepLine,
		stepLineBack: stepLineBack,
		gotoTimeMS: gotoTimeMS,
		setPlaybackSpeed: setPlaybackSpeed
	};
}