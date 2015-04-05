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
 * @version $Id: source-file-tracer.js 2522 2015-02-19 23:14:55Z wpultz $
 * @author wpultz
 * @class journal.source-file-tracer
 * @param {Array} _fileNameLookup array of file names/hashes
 * @param {numeric} _filesToShow number of files to initially to show in the file trace
 * @param {jQuery} _$cont jQuery object specifying the DOM element to use for the file trace
 */
function SourceFileTrace( _fileNameLookup, _filesToShow, _$cont ) {
	var lastJournalLine,
		currentLineNum,
		currentFile,
		currentFileId,
		contentCache = new SourceFileContentCache( _fileNameLookup ),
		sourceFileFactory = new SourceFileFactory( contentCache ),
		filesToShow = _filesToShow && ( _filesToShow > 0 ) ? _filesToShow : 1,
		$cont = _$cont,
		fileHeight = 0;


	/**
	 * @method stepForward
	 * @param {Object} _edat mapping of data defining what line of what file should be focused on and highlighted
	 */
	var stepForward = function( _edat ) {
		if ( _edat.currentJournalLine && _edat.currentFileId && _edat.currentLineNum ) {
			setCurrent( _edat );
			if ( !currentFile || ( currentFile.getId() != currentFileId ) ) {
				currentFile = sourceFileFactory.getSourceFile( currentFileId, '', '' );
				addSource( currentFile );
			}
			currentFile.highlightLine( currentLineNum );
		}
	};


	/**
	 * @method stepBack
	 * @param {Object} _edat mapping of data defining what line of what file should be focused on and highlighted
	 */
	var stepBack = function( _edat ) {
		if ( _edat.currentJournalLine && _edat.currentFileId && _edat.currentLineNum ) {
			setCurrent( _edat );
			if ( !currentFile || ( currentFile.getId() != currentFileId ) ) {
				currentFile = sourceFileFactory.getSourceFile( currentFileId, '', '' );
				addSource( currentFile );
			}
			currentFile.highlightLine( currentLineNum );
		}
	};


	/**
	 * @private
	 * @method addSource
	 * @param {Object} _fil source file object
	 */
	var addSource = function( _fil ) {
		var $sessionCont = $cont.find( '#var-cont' );
		if ( $sessionCont.length ) {
			$sessionCont.before( _fil.getContent() );
		} else {
			$cont.append( _fil.getContent() );
		}
		arrangeFiles();
	};


	/**
	 * @method setFilesToShow
	 * @param {numeric} _num number of files to display in the file trace
	 */
	var setFilesToShow = function( _num ) {
		filesToShow = _num;
		arrangeFiles();
	};


	/** 
	 * clears out the files in view and displays/highlights the line in the file specfied
	 * @method gotoLine
	 * @param {Object} _edat mapping of data defining what line of what file should be focused on and highlighted
	 */
	var gotoLine = function( _edat ) {
		// first clear out the container and reset things, in case bogus-ness happens
		clear();
		if ( _edat.currentJournalLine && _edat.currentFileId && _edat.currentLineNum ) {
			setCurrent( _edat );
			currentFile = sourceFileFactory.getSourceFile( currentFileId, '', '' );
			addSource( currentFile );
			currentFile.highlightLine( currentLineNum );
		}
	};


	/** 
	 * @method clear
	 */
	var clear = function() {
		$cont.find( '.source-wrapper' ).remove();
		currentFile = null;
		currentFileId = -1;
		currentLineNum = -1;
		lastJournalLine = -1;
	};


	/**
	 * @private
	 * @method setCurrent
	 * @param {Object} _edat mapping of data defining what line of what file should be focused on and highlighted
	 */
	var setCurrent = function( _edat ) {
		lastJournalLine = _edat.currentJournalLine;
		currentLineNum = _edat.currentLineNum;
		currentFileId = _edat.currentFileId;
	};


	/** 
	 * @private
	 * @method arrangeFiles
	 */
	var arrangeFiles = function() {
		var $sourceChildren = $cont.children( '.source-wrapper' );

		// remove source file children that exceed the max number of files to show
		for ( var i = 0, clen = $sourceChildren.length; i < clen; i++ ) {
			// remove leftmost children first
			if ( i - filesToShow >= 0 ) {
				$sourceChildren[ i - filesToShow ].remove();
			}
		}

		// find the total number of children, and adjust classes accordingly
		var $chldrn = $cont.children(),
			total = $chldrn.length,
			sessionChbx = $( '#showSessionDump' );

		// adjust total if session data not shown
		if ( !sessionChbx || !sessionChbx.is( ':checked' ) ) {
			total--;
		}

		fileHeight = Math.max( fileHeight, document.getElementById( 'container' ).clientHeight - document.getElementById( 'timeline' ).offsetHeight );
		console.log( total );
		for ( var c = 0; c < total; c++ ) {
			if ( $chldrn[ c ].className.indexOf( 'pure-u' ) >= 0 ) {
				$chldrn[ c ].className = $chldrn[ c ].className.replace( /pure-u-[0-9]-[0-9]/g, 'pure-u-1-' + total );
			} else {
				$chldrn[ c ].className += ' pure-u-1-' + total;
			}
		}
		$( '.source-file' ).css( 'height', fileHeight );

	};


	// expose public functions
	return {
		stepForward: stepForward,
		stepBack: stepBack,
		gotoLine: gotoLine,
		setFilesToShow: setFilesToShow,
		arrangeFiles: arrangeFiles,
		clear: clear
	};
}