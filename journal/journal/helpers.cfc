<!---
	OpenBD Journaling Tool
  Copyright (C) 2015

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
--->
<cfcomponent output="false"><cfscript>

	/**
		* @version $Id: helpers.cfc 2522 2015-02-19 23:14:55Z wpultz $
		*
		* @Class journaling.journal.helpers
		*/


	/**
		* Returns an array of colors
		*
		* @method getColors
		* @public
		* @param {numeric} cnt (required)
		* @return {any}
		*/
	public function getColors( required numeric cnt ) {
		clrs = ["##023FA5",
						"##7D87B9",
						"##BEC1D4",
						"##D6BCC0",
						"##4A6FE3",
						"##8595E1",
						"##B5BBE3",
						"##E6AFB9",
						"##E07B91",
						"##D33F6A",
						"##11C638",
						"##8DD593",
						"##C6DEC7",
						"##EAD3C6",
						"##F0B98D",
						"##EF9708",
						"##0FCFC0",
						"##9CDED6",
						"##D5EAE7",
						"##F3E1EB",
						"##F6C4E1",
						"##F79CD4"];

		var ret = [];
		for ( i = 1; i <= arguments.cnt; i++ ) {
			arrayAppend(ret, clrs[i]);
		}

		return ret;
	}

	/**
		* Remote (AJAX) function for getting the latest journal files timestamp
		*
		* @method latestJournalTimestamp
		* @remote
		* @return {any}
		*/
	remote function latestJournalTimestamp() returnformat='plain' {
		var everything = directoryList( ArgumentCollection= {	path:GetJournalDirectory(),
																													recurse:true,
																													sort:'datelastmodified desc',
																													filter:'*.txt'} );
		if ( arrayLen(everything) > 0 ) {
			return ListLast(everything[1], fileSeparator());
		} else {
			return 'none';
		}
	}



	/**
		* Converts bytes to readable format, kB and MB
		*
		* @method getNiceSizeFormat
		* @public
		* @param {numeric} _bytes (required)
		* @return {any}
		*/
	public function getNiceSizeFormat( required numeric _bytes ) {
		var bytesIn = arguments._bytes;
		var ret = '';

		if ( bytesIn >= 1073741824 ) {
			ret = numberFormat( bytesIn / 1073741824, '9.9') & ' GB';
		} else if ( bytesIn >= 1048576 ) {
			ret = numberFormat( bytesIn / 1048576, '9.9') & ' MB';
		} else if ( bytesIn >= 1024 ) {
			ret = numberFormat( bytesIn / 1024, '9.9') & ' kB';
		} else {
			ret = '1> kB';
		}
		return ret;
	}

	/**
	* Converts a journal file path to a relative to webroot journal file path
	*
	* @method getWebRootRelativeJournalFilePath
	* @public
	* @param {string} _journal_file_path (required)
	* @param {string} _file_path_to_webroot (required)
	* @return {string}
	*/
	public string function getWebRootRelativeJournalFilePath( required string _journal_file_path, required string _file_path_to_webroot ) {

		//journal file paths are not OS specific
		var journalFilePathToWebRoot = replace( arguments._file_path_to_webroot, "\", "/", "ALL" );

		return "/" & replace( arguments._journal_file_path, journalFilePathToWebRoot, "" );
	}

</cfscript></cfcomponent>