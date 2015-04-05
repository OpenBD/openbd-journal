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

<cfcomponent><cfscript>
/** 
	* @version $Id: browser.cfc 2522 2015-02-19 23:14:55Z wpultz $
	*
	* @class journal.browser
	*/

	this._sPath = GetJournaldirectory();

	/**
		* Query all journals in _sPath(optional) that begin with _sFile(optional)
		*
		* @method queryAllJournals
		* @public
		* @param {string} [_sPath = ""] part of a file path, will be appended to the journal directory
		* @param {string} [_sFile = ""] part of a file name, will look for _sFile*.txt
		* @return {query} directory listing
		*/
	public query function queryAllJournals(string _sPath="", string _sFile=""){
		if (left(_sPath,1) != fileSeparator()){
			arguments._sPath = fileSeparator() & arguments._sPath;
		}
		return DirectoryList(this._sPath & arguments._sPath, true, "query", "#arguments._sFile#*.txt", "datelastmodified desc");
	}



	/**
		* Gets the newest journal in _sPath(optional) that begin with _sFile(optional)
		*
		* @method getLatestJournal
		* @public
		* @param {string} [_sPath = ""] part of a file path, will be appended to the journal directory
		* @param {string} [_sFile = ""] part of a file name, will look for _sFile*.txt
		* @return {string} the full path of the most recent journal, "" if no file found
		*/
	public string function getLatestJournal(string _sPath="", string _sFile=""){
		// Get all journals, then grab just the latest one
		var qDir = this.queryAllJournals(argumentCollection=arguments);
		if (qDir.recordCount >= 1){
			return qDir.directory[1] & '/' & qDir.name[1];
		}
		return "";
	}



	/**
		*	Purge journals in _sPath(optional) that begin with _sFile(optional)
		*
		* @method purgeJournals
		* @public
		* @param {string} [_sPath = ""] part of a file path, will be appended to the journal directory
		* @param {string} [_sFile = ""] part of a file name, will look for _sFile*.txt
		* @return {boolean} bSuccess, true if all delets were successful, false if at least 1 failed
		*/
	public boolean function purgeJournals(string _sPath="", string _sFile=""){
		var qDir = this.queryAllJournals(argumentCollection=arguments);
		var bSuccess = true;
		for (dir in qDir) {
			bSuccess = this.purgeJournal(Dir.directory & '/' & Dir.name) && bSuccess;
		}
		return bSuccess;

	}



	/**
		* Deletes journal file
		*
		* @method purgeJournal
		* @public
		* @param {string} _sFullPath full path to the journal file
		* @return {boolean} fileDelete(arguments._sFullPath)
		* @return {boolean} false
		*/
	public boolean function purgeJournal(string _sFullPath){
		try {
			var sFile = arguments._sFullPath & '.session';
			if ( fileExists(sFile) ) {
				fileDelete(sFile);
			}
			return fileDelete(arguments._sFullPath);
		} catch(any e){
			return false;
		}
	}



	/**
		* Returns a specific journal
		*
		* @method GetJournal
		* @public
		* @param {string} _sFullPath
		* @return {component}
		*/
	public component function getJournal(string _sFullPath){
		return new parser(arguments._sFullPath);
	}



	/**
		* Get details about a journal
		*
		* @method getJournalDetails
		* @public
		* @param {string} _sFullPath full path to the journal file
		* @return {struct} that will contain basic information on the journal
		*/
	public struct function getJournalDetails(string _sFullPath){
		var journal = new parser(arguments._sFullPath);

		return journal.info;
	}

</cfscript></cfcomponent>