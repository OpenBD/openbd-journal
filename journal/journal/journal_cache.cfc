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
* @version $Id: journal_cache.cfc 2522 2015-02-19 23:14:55Z wpultz $
* @author wpultz
* @class journal.journal-cache
*/
component output="false" {

	this.CACHE_TIMEOUT = CreateTimeSpan( 0, 0, 5, 0 );


	/**
	* @method getJournal
	* @param {String} _journalFile
	* @return {struct}
	*/
	public struct function getJournal( _journalFile ) {
		return getFromCache( _journalFile );
	}


	/**
	* @method getJournalEntries
	* @param {String} _journalFile name of the journal file to get entries from
	* @param {numeric} _start first line to get from the file
	* @param {numeric} _stop last line to get from the file
	* @return {struct} map containing the array of entries, as well as the session dumps for the sessions in the array
	*/
	remote struct function getJournalEntries( _journalFile, _start=-1, _stop=-1 ) returnformat="JSON" {
		var jrnl = getFromCache( _journalFile );

		// get query of journal entries
		var parser = new parser( GetJournalDirectory() & _journalFile );
		var entriesQry = parser.getEntries( _start, _stop );
		var entries = queryToArr( entriesQry );

		// get unique sessions for the entries
		var sessions = {};
		for( var i = 1; i <= ArrayLen( entries ); i++ ) {
			if( entries[i].session > 0 && !StructKeyExists( sessions, entries[i].session ) ) {
				//sessions[entries[i].session] = getVarSessionFromCache( _journalFile, entries[i].session );
				sessions[entries[i].session] = Render( "<cfdump var=""##getVarSessionFromCache( _journalFile, entries[i].session )##"" />" );
			}
		}

		return { entries: entries, sessions: sessions, journallen: ArrayLen( jrnl.entries ) };
	}


	/**
	* get first journal entry for the specified time offset, buffered with journal entries before and after
	*
	* @method getJournalEntriesMS
	* @param {String} _journalFile
	* @param {numeric} _ms
	* @param {numeric} _entryBuffer
	* @return {struct}
	*/
	remote struct function getJournalEntriesMS( _journalFile, _ms, _entryBuffer ) returnformat="JSON" {
		var jrnl = getFromCache( _journalFile );

		// get query of journal entries
		var parser = new parser( GetJournalDirectory() & _journalFile );
		var entriesQry = parser.getEntriesMS( _ms, _entryBuffer );
		var entries = queryToArr( entriesQry );

		// get unique sessions for the entries
		var sessions = {};
		for( var i = 1; i <= ArrayLen( entries ); i++ ) {
			if( entries[i].session > 0 && !StructKeyExists( sessions, entries[i].session ) ) {
				//sessions[entries[i].session] = getVarSessionFromCache( _journalFile, entries[i].session );
				sessions[entries[i].session] = Render( "<cfdump var=""##getVarSessionFromCache( _journalFile, entries[i].session )##"" />" );
			}
		}

		return { entries: entries, sessions: sessions, journallen: ArrayLen( jrnl.entries ) };
	}


	/**
	* @private
	* @method queryToArr
	* @param {query} _qry
	* @returns {array}
	*/
	private array function queryToArr( _qry ) {
		// turn the query into an array, so that we know what's actually going on
		var cols = ListToArray( _qry.getColumns() );
		for( var i = 1; i <= ArrayLen( cols ); i++ ) {
			cols[ i ] = LCase( cols[ i ] );
		}

		var rows = [];
		for( var i = 1; i <= _qry.RecordCount; i++ ) {
			var row = {};
			for( var j = 1; j <= ArrayLen( cols ); j++ ) {
				row[ cols[ j ] ] = _qry[ cols[ j ] ][ i ];
			}
			ArrayAppend( rows, row );
		}
		return rows;
	}


	/**
	* @private
	* @method getVarSessionFromCache
	* @param {String} _journalFile
	* @param {numeric} _sessionId
	* @return {struct}
	*/
	private struct function getVarSessionFromCache( _journalFile, _sessionId ) {
		var cacheId = _journalFile & "_sess_" & _sessionId;

		var sess = CacheGet( cacheId );

		if( !IsNull( sess ) ) {
			return sess;
		}

		var sessContent = {};
		try {
			sessContent = JournalReadSession( GetJournalDirectory() &  fileSeparator() & _journalFile, _sessionId );
		} catch( any err ) {
			// bollocks, allow to default to empty map
			console( err );
		}

		CachePut( cacheId, sessContent, this.CACHE_TIMEOUT );

		return sessContent;
	}


	/**
	* @private
	* @method getFromCache
	* @param {String} _journalFile name of the journal file to get from cache
	* @return {struct} data describing the journal file
	*/
	private struct function getFromCache( _journalFile ) {
		var jrnl = CacheGet( _journalFile );

		var dbColumnAliases = "t_offset as t_offset, code as code, file_id as file_id, session as session, file_depth as file_depth, tag_depth as tag_depth, tag as tag, line as line, col as col, fn as fn, scriptline as scriptline, journalid as journalid, id as id";

		if( !IsNull( jrnl ) ) {
			return jrnl;
		}

		// build the absolute path to the journal file
		var journalPath = GetJournalDirectory() & fileSeparator() & _journalFile;

		// report.journal.files is the lookup for the file names
		// report.tree is the array of frames
		var report = new executionTree( journalPath );
		report.buildTree();

		// get query of all frames that occurred during the journalled request
		var allEntries = queryRun("journaling", "SELECT " & dbColumnAliases & " FROM journal");

		var qry = "SELECT * FROM allEntries WHERE code NOT IN (?)";
		var qryParams = [ { value: "FE,ME", type: "LIST" } ];

		// find the file id for the base openbd component.cfc so we can filter that out of the entries
		for( var i = 1; i <= ArrayLen( report.journal.files ); i++ ) {
			if( report.journal.files[i].name.endsWith( "bluedragon/component.cfc" ) ) {
				qry &= " AND file_id != ?";
				ArrayAppend( qryParams, { value: i } );
			}
		}

		allEntries = QueryOfQueryRun( qry, qryParams );

		var entries = [];
		for( var row in allEntries ) {
			ArrayAppend( entries, row );
		}

		// cache the file execution regions as well
		jrnl = {
			session_capture: ( StructKeyExists( report.journal.info, "_session" ) ? report.journal.info._session : false ),
			abspath: journalPath,
			files: report.journal.files,
			entries: entries,
			file_blocks: report.tree
		};

		CachePut( _journalFile, jrnl, this.CACHE_TIMEOUT );

		return jrnl;
	}

}