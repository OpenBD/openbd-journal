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
		* $Id: parser.cfc 2522 2015-02-19 23:14:55Z wpultz $
	  *
	  * @Class journaling.journal.parser  <-- Needs to go before releasing to public, hardcoded to our path
	  *
		* Journal information can be found at http://openbd.org/manual/?/journal
		*/


	this.files = [];
	this.sPath = "";
	this.info = {};
	this.aSource = [];
	this.aCoverage = [];
	this.timestamp = '';
	this.filename = '';

	//Use aliases to lowercase column names
	this.dbColumnAliases = "t_offset as t_offset, code as code, file_id as file_id, session as session, file_depth as file_depth, tag_depth as tag_depth, tag as tag, line as line, col as col, fn as fn, scriptline as scriptline, journalid as journalid, id as id, filesbetween as filesbetween";



	/**
		* Initializes component, does not load the journal into memory
		*
	  * @method init
	  * @public
	  * @param {string} _sPath (required) full path to a journal file
	  * @return {component}
	  * @throws error if journal file is malformed or cannot be read into database
	  */
	public component function init(required string _sPath){
		this.sPath = Trim(arguments._sPath);

		// Get basic file information
		this.fileInfo = getFileInfo( this.sPath );
		this.info._fileSize = this.fileInfo.size;
		this.timestamp = this.fileInfo.lastmodified;
		this.filename = this.fileInfo.name;
		
		// Calculate the relative file path to the journal directory
		this.relativeToJournal = Replace( this.sPath, GetJournalDirectory(), '' ).replace("\","/");
		
		// For database id, ensures that IDs are unique and easy to replicate elsewhere if needed
		this.journalShort = Right(reReplace(this.filename, "[^0-9]", "", "ALL"), 8);

		// Read journal into the database, if it's not already present
		try {
			if ( queryRun("journaling", "SELECT distinct(id) FROM journal WHERE id=#this.journalShort#").recordCount == 0 ) {
				JournalReadToDataSource( datasource="journaling", file=this.sPath, id=this.journalShort );
			}
		} catch( any e ) {
			if ( e.detail contains 'Table "JOURNAL" not found' ) {
				JournalReadToDataSource( datasource="journaling", file=this.sPath, id=this.journalShort );
			}
		}


		//get just the header form the journal
		var uDetails = journalRead(this.sPath,false);

		var fCount = 0;

		// Loop over the journal details, and separate info from files
		/**
			*	Any key that is prefixed with an underscore (_) is a system key.
			*	An example of this includes:
			*		_uri (the original request),
			*		_bytes (the number of bytes sent),
			*		_timems (time for request),
			*		_querycount (number of queries ran),
			*		_querytime (time the queries took),
			*		_method (the HTTP method of the request).
			*	All the other keys are the full path names of the files that this particular request read.
			*	This includes all CFC's, include's, template's etc.
			*	The key is pointed to a unique number that is referenced in the remaining lines.
			*/
		for (fld in uDetails){

			if (left(fld,1)!="_" && isStruct(uDetails[fld]) && uDetails[fld].id > 0){
				//we have no guarantee the files are coming in order, always have to make sure the array is sized properly
				if (!arrayIndexExists(this.files,uDetails[fld].id)){
					arrayResize(this.files, uDetails[fld].id); //creates an array with new indexes set to NULL
				}
				//convert {FILENAME:{id:ID, hash:HASH}} to [{name:FILENAME, hash:HASH}] where the array index=ID
				this.files[uDetails[fld].id] = {	name:fld, hash:uDetails[fld].hash};
			} else if (left(fld,1) == "_") {//store non-file information seperately
				this.info[fld] = uDetails[fld];
			}
		}

		// Size other array related the source files, so they all mathc
		arrayResize(this.aSource,arrayLen(this.files));		//creates an array with all NULL values
		arrayResize(this.aCoverage,arrayLen(this.files));	//creates an array with all NULL values

		return this;
	}



	/**
	  * @method getEntries
	  * @public
	  * @param {numeric} [_begin = -1]
	  * @param {numeric} [_end = -1 ]
	  * @return {query}
	  */
	public query function getEntries( numeric _begin=-1, numeric _end=-1 ) {
		var qry = "SELECT * FROM journal WHERE id = " & this.journalShort;
		if( _begin != -1 ) {
			qry &= " AND journalid >= " & _begin;
		}
		if( _end != -1 && _end > _begin ) {
			qry &= " AND journalid <= " & _end;
		}
		var entries = QueryRun( "journaling", qry );

		return entries;
	}


	/**
		* @method getEntriesMS
		* @param {numeric} _ms
		* @param {numeric} _bufferSize
		* @return {query}
		*/
	public query function getEntriesMS( required numeric _ms, required numeric _bufferSize ) {
		var qry = QueryRun( "journaling", "SELECT * FROM journal WHERE id = " & this.journalShort & " AND t_offset >= " & _ms );
		if( qry.RecordCount > 0 ) {
			var index = qry.journalid[1];
			var qry = "SELECT * FROM journal WHERE id = " & this.journalShort & " AND journalid > " & index - _bufferSize & " AND journalid < " & index + _bufferSize & " ORDER BY journalid ASC";
			return QueryRun( "journaling", qry );
		} else {
			var qry = "SELECT * FROM journal WHERE id = " & this.journalShort & " AND journalid > 0 AND journalid < " & _bufferSize & "ORDER BY journalid ASC";
			return QueryRun( "journaling", qry );
		}
	}



	/**
		* Returns all the full paths to source files
		*
	  * @method getFiles
	  * @public
	  * @return {array}
	  */
	public array function getFiles(){
		return this.files;
	}



	/**
		* Given a file Id, returns the filename
		*
	  * @method getFile
	  * @public
	  * @param {numeric} _idx (required)
	  * @return {string} this.files[arguments._idx]
	  * @return {string} "Index #arguments._idx# does not exist"
	  */
	public string function getFile(required numeric _idx){
		if (arrayIndexExists(this.files,arguments._idx)){
			return this.files[arguments._idx].name;
		}
		return "Index #arguments._idx# does not exist";
	}



	/**
		* Given a file ID, returns the files hash
		*
	  * @method getFileHash
	  * @public
	  * @param {numeric} _idx (required)
	  * @return {string}
	  */
	public string function getFileHash(required numeric _idx){
		if (arrayIndexExists(this.files,arguments._idx)){
			return this.files[arguments._idx].hash;
		}
		return "Index #arguments._idx# does not exist";
	}



	/**
	  * Given a file_id, return the relative filename to the webroot
	  *
	  * @method getPrettyFile
	  * @remote
	  * @param {numeric} _idx (required)
	  * @param {string} [_journal = '']
	  * @return {string}
	  */
	remote string function getPrettyFile(required numeric _idx, string _journal='') returnformat='plain'{
		if( len(arguments._journal) > 0 ) {
			this.init( _sPath = getJournalDirectory() & arguments._journal );
		}
		return "/" & replace(this.getFile(arguments._idx), expandPath("/").replace("\","/"), "");
	}



	/**
	  * Load all the source files for this journal
	  *
	  * @method loadAll
	  * @public
	  */
	public void function loadAll(){
		for (var i=1; i<=arrayLen(this.getFiles()); i++){
			this.getSource(i);
		}
	}



	/**
	  * Given a file ID, get the source object
	  * @method GetSource
	  * @public
	  * @param {numeric} _idx numeric id of the file as defined in the journal file name lookup
	  * @return {component} journal.source
	  */
	public component function GetSource(required numeric _idx){
		// If we already have the source loaded, return it, other wise, go get it
		try {
			return this.aSource[sfullPath];
		} catch (any e){
			// Get the number of lines related to this file for stat purpose
			var lines = this.distinctLinesByFile(_idx);
			// Get the source
			this.aSource[arguments._idx] = new source(this.getFile(arguments._idx), this.getFileHash(arguments._idx));

			// Make sure we have lines that were covered, and that the source file has source code in it to calculate coverage with
			if (lines.recordCount > 0 && this.aSource[arguments._idx].uStats.nSource > 0){
				this.aCoverage[arguments._idx] = lines.recordCount/this.aSource[arguments._idx].uStats.nSource;
			} else {
				this.aCoverage[arguments._idx] = 0;
			}
			return this.aSource[arguments._idx];
		}
	}



	/**
		* Returns the code coverage for the file id given
		*
	  * @method getCoverage
	  * @public
	  * @param {numeric} _idx (required)
	  * @return {numeric}
	  */
	public numeric function getCoverage(required numeric _idx){
		// If we already have the coverage calculated, return it, otherwise, go get it
		try {
			return this.aCoverage[arguments._idx];
		} catch (any e){
			this.getSource(arguments._idx);
			return this.aCoverage[arguments._idx];
		}
	}



	/**
	  * AJAX entry point for getting data used for donuts
	  *
	  * @method ajaxGetInfo
	  * @remote
	  * @param {string} _journal (required)
	  * @param {numeric} _fileId (required)
	  * @param {string} [_type = 'coverage' ]
	  * @return {any}
	  */
	remote any function ajaxGetInfo( required string _journal, required numeric _fileId, required string _type = 'coverage' ) returnformat="json" {
		// Need to initialize component before pulling data.
		this.init( _sPath = getJournalDirectory() & arguments._journal );

		// The type of data is always through arguments._type
		switch( arguments._type ){
			case 'breakdown':
				var q = this.getTagUsage(arguments._fileId);
			break;

			case 'coverage':
				var temp = this.getCoverage(arguments._fileId);
				var q = { 'a': Int(temp * 100), 'b': Int(100 - (temp * 100)) };
			break;

			default:
				throw ("Unsupported _type (" & arguments._type & ")");
			break;
		}
		return q;
	}


	/**
		* Get a breakdown of how many of what tags are used, can limit to a file
		*
	  * @method getTagUsage
	  * @public
	  * @param {numeric} [_idx = -1]
	  * @return {query}
	  */
	public query function getTagUsage(numeric _idx=-1){
		/*Only looking at the follow journal codes
		 * TS - Tag Start
		 * TT - Tag (with no end tag)
		 * TE - Tag End
		 */
		var where = "WHERE code IN ('TT', 'TE')";
		if (arguments._idx != -1){
			where &= " AND file_id=#arguments._idx#";
		}
		var ret = queryrun("journaling", "SELECT tag, count(1) as cnt FROM journal #where# AND id=#this.journalShort# GROUP BY tag");
		return ret;
	}


	/**
		* returns the decimal coverage amount for all source files
		*
	  * @method getTotalCoverage
	  * @public
	  * @return {numeric}
	  */
	public numeric function getTotalCoverage(){
		//Load all the source
		this.loadAll();
		//return an average of coverage for all files in this journal
		return arrayAvg(this.aCoverage);
	}



	/**
	  * Compile all the source files stats to a journal level
	  *
	  * @method getTotalStats
	  * @public
	  * @return {struct}
	  */
	public struct function getTotalStats(){
		//base stat struct
		var total = {	nBlank:0,
									nComments:0,
									nSource:0,
									nTag:0,
									nScript:0,
									nOther:0,
									nCoverage:0};
		//loop of all files
		for (var i=1; i<=arrayLen(this.getFiles()); i++){
			//get the source
			var tmp = this.getSource(i);
			//loop over all stats for the source
			for (f in tmp.uStats){
				//add the like stats together
				total[f] += tmp.uStats[f];
			}
		}
		return total;
	}



	/**
	  * get all lines that were used for a given file, optionally between a start and end marker
	  *
	  * @method linesByFile
	  * @public
	  * @param {numeric} _idx (required) file id
	  * @param {numeric} [lineStart = 0] journal line number to start after
	  * @param {numeric} [lineEnd = 0] journal line number to end before
	  * @return {query}
	  */
	public query function linesByFile(required numeric _idx, numeric lineStart=0, numeric lineEnd=0){
		//build the where clause for the QoQ
		var where = "WHERE file_id=?";
		var auParams = [{value:arguments._idx, cfSQLType:"CF_SQL_INTEGER"}];

		//check for optional line start
		if (arguments.lineStart != 0){
			where &= " AND journalid >= ?";
			arrayAppend (auParams,{value:arguments.lineStart, cfSQLType:"CF_SQL_INTEGER"});
		}

		//check for optional line end
		if (arguments.lineEnd != 0){
			where &= " AND journalid <= ?";
			arrayAppend (auParams,{value:arguments.lineEnd, cfSQLType:"CF_SQL_INTEGER"});
		}

		var lines = queryrun("journaling", 	"SELECT journalid as journalid, id as id, session as session, t_offset as t_offset, code as code ,file_id as file_id, file_depth as file_depth, tag_depth as tag_depth, tag as tag, line as line, col as col, fn as fn, scriptline as scriptline, '' as filesBetween "&
																				"FROM journal " & where & ' AND id=#this.journalShort#',
																				auParams);

		if (lines.recordCount >= 1){
			//for every line that we return for this file, we need to see if there are other journal lines between this, and the next line
			var prev=lines.journalid[1];
			for (var i=1; i <= lines.recordCount; i++){

				if (lines.journalid[i]-1 > prev){
					//get the file ids for files that were touch between this line, and next
					querySetCell(lines,"filesBetween",this.getFilesBetween(prev, lines.journalid[i]),i-1);
				}
				prev = lines.journalid[i];

			}
		}
		return lines;
	}



	/**
	  * Get a list of all files that were touched between a begina and end marker
	  *
	  * @method getFilesBetween
	  * @private
	  * @param {numeric} _nBegin (required)
	  * @param {numeric} _nEnd (required)
	  * @return {string}
	  */
	private string function getFilesBetween(required numeric _nBegin, required numeric _nEnd){
		//select all distinct file_id between the start and end boundry that are not FE: File End
		var lines = queryrun("journaling", 	"SELECT distinct (file_id) as file_id "&
																				"FROM journal "&
																				"WHERE id=#this.journalShort# AND journalid>? AND journalid<? AND code NOT IN ('FE')",
																				[{value:arguments._nBegin, cfSQLType:"CF_SQL_INTEGER"},
																				 {value:arguments._nEnd, cfSQLType:"CF_SQL_INTEGER"}]);

		//conver the query to a list
		var result = "";
		for (var line in lines){
			result = listAppend(result,line.file_id);
		}
		return result;
	}


	/**
	  * @method distinctLinesByFile
	  * @public
	  * @param {numeric} _idx (required)
	  * @param {numeric} [lineStart = 0]
	  * @param {numeric} [lineEnd = 0]
	  * @return {query}
	  */
	public query function distinctLinesByFile(required numeric _idx, numeric lineStart=0, numeric lineEnd=0){
		var where = "WHERE line > 0 AND file_id=? AND id=#this.journalShort#";
		var auParams = [{value:arguments._idx, cfSQLType:"CF_SQL_INTEGER"}];

		if (arguments.lineStart != 0){
			where &= " AND journalid >= ?";
			arrayAppend (auParams,{value:arguments.lineStart, cfSQLType:"CF_SQL_INTEGER"});
		}

		if (arguments.lineEnd != 0){
			where &= " AND journalid <= ?";
			arrayAppend (auParams,{value:arguments.lineEnd, cfSQLType:"CF_SQL_INTEGER"});
		}

		cacheCheck = CacheGet(where);

		if ( len(cacheCheck) == 0 ) {
			var lines = queryRun("journaling", 	"SELECT distinct(line) as line "&
																					"FROM journal "& where,
																					auParams);
			cacheput(SerializeJson(where), lines);
		} else {
			var lines = DeSerializeJson(cacheCheck);
		}
		return lines;
	}


	/**
	  * Get the maximum file depth that execution goes
	  *
	  * @method MaxFileDepth
	  * @public
	  * @return {numeric}
	  */
	public numeric function MaxFileDepth(){
		//select the max file_depth
		var maxDepth = queryrun("journaling", "SELECT max(file_depth) as cnt FROM journal");
		return maxDepth.cnt[1];
	}


	/**
	  * Get the maximum tag dept that execution goes
	  * @method maxTagDepth
	  * @public
	  * @return {numeric}
	  */
	public numeric function maxTagDepth(){
		//select the max tag depth
		var maxDepth = queryrun("journaling", "SELECT max(tag_depth) as cnt FROM journal ");
		return maxDepth.cnt[1];
	}



	/**
	  * Get the total execution time length
	  *
	  * @method totaExecutionLength
	  * @public
	  * @return {numeric}
	  */
	public numeric function totaExecutionLength(){
		//select the max time of execution
		var maxDepth = queryrun("journaling", "SELECT max(t_offset) as cnt FROM this.journal ");
		return maxDepth.cnt[1];
	}


</cfscript>



<!---
		/**
			* Render the source file, with lines highlighed with coverage from a journal, and optionaly between certain lines
			*
			* Returns a string
			*
		  * @remote
		  * @method renderSourceCoverage
		  * @param {any} _file (required)
		  * @param {any} _journal (required)
		  * @param {any} _jLineStart
		  * @param {any} _jLineEnd
		  * @returnformat {plain}
		  * @return {string}
		  */
		--->
<cffunction name="renderSourceCoverage" access="remote" returntype="string" returnformat="plain">
			<cfargument name="_file" required="true">
			<cfargument name="_journal" required="true">
			<cfargument name="_jLineStart" required="false" default=0>
			<cfargument name="_jLineEnd" required="false" default=0>
			<cfscript>
				//load the journal file
				this.init(GetJournaldirectory() & arguments._journal);
				//get the pretty file name
				var theFileName = this.getPrettyFile( arguments._file );
				var redLines 		= 0;
				var greenLines 	= 0;
				var multiline 	= "";

				//get the journal lines related to this source file
				var lbf = this.linesByFile( _idx = arguments._file, lineStart = arguments._jLineStart, lineEnd = arguments._jLineEnd );

				//get the source file
				var srcObj = this.getSource( arguments._file );
				//get the lines of source code
				var src = srcObj.getSourceLines();
				arrayDeleteAt(src, arraylen(src));

				//figure out what the first and last lines of the source we need for this section of journal
				var minMaxLines = queryNew("mn,mx");
				if (arguments._jLineStart!= 0 && arguments._jLineEnd != 0){
					var minMaxLines = queryOfQueryRun("SELECT MIN(line) as mn, MAX(line) as mx " &
																						"FROM lbf " &
																						"WHERE line <> '' and tag NOT IN('CFCOMPONENT','CFSCRIPT')");

				}
			</cfscript>

			<cfset var theTable="">
			<cfset counter = 1>

			<!--- Set up the table to be returned and rendered --->
			<cfsavecontent variable="theTable" trim="true">
			<div class="source-wrapper">
				<div class="source-file-title"><cfoutput>#theFileName#</cfoutput></div>
				<div class="source-file">
					<table class="pure-table pure-table-horizontal">
						<cfloop from="1" to="#arrayLen(src)#" index="i">
							<cfsilent><cfscript>
								// Prepare src[i] to be displayed with intact whitespace
								src[i].code = HTMLEditFormat(src[i].code);
								var rowClass="";

								//if we are outside the include area, mark as excluded
								if (arguments._jLineStart > 0 && arguments._jLineEnd > 0  && (i < minMaxLines.mn[1] || i > minMaxLines.mx[1]) ){
									rowClass = "exclude";
								}

								//check for coverage of this line
								var journalLine 	= queryOfQueryRun("SELECT " & this.dbColumnAliases & " FROM lbf WHERE line=#i# ORDER BY journalid");
								var filesBetween 	= "";
								var filesMarker 	= "&nbsp;";
								var codeClass 		= "";

								//check for files files between this journal line and the next line
								for (row in journalLine){
									first = listFirst(row.filesBetween);

									if (listContains(filesBetween,first)==0){
										filesBetween = listAppend(filesBetween,first);
									}
								}

								//if we have lines between this and the next line, mark it
								if (len(filesBetween)>0){
									//set marker for extra file content
									filesMarker = "&##x21e8;";

									//get the next journal line id for this file after the current
									var journalLine2 = queryOfQueryRun("SELECT min(journalid) as journalid FROM lbf WHERE journalid>#journalLine.journalid[1]#");

									//build a tag for custom click use
									src[i].code = Replace(src[i].code, Trim(src[i].code), '<a href="##" data-journal="#arguments._journal#" '&
																																											'data-file="#listFirst(filesBetween)#" '&
																																											'data-lineStart="#journalLine.journalid[1]#" '&
																																											'data-lineEnd="#journalLine2.journalid[1]#">#trim(src[i].code)#</a>', 'ALL');
								}
								//add class to non-blank, and lines with content
								if (!src[i].blank && src[i].content != ""){
									//check if we are already on a multiline statment
									if (multiline != ""){
										//multiline statments continue the class of the begining line
										codeClass = multiline;
										//if we find a Tag End (TE) or Script End (SE), we are done with the multiline
										if (listFind("TE,SE",src[i].content)){
											multiline = "";
										}
									} else {

										if (listFind("CB,CC,CE,C",src[i].content)>=1){
											//this line is a comment, no coverage related
											codeClass = "hlGrey";
										} else if (journalLine.recordCount==0){
											//this line was not covered
											codeClass = "hlRed";
										} else {
											//this line was covered
											codeClass = "hlGreen";
										}

										//check for multiline, so we can flag most multiline statment under the correct class
										if (listFind("TB,SB",src[i].content)>=1){
											multiline = codeClass;
										}
									}
								}

							</cfscript></cfsilent>
							<cfoutput><!--- Render a line based on everything we have alredy figured --->
								<tr data-linenum="#i#" class="#rowClass#">
									<td class="marker">#filesMarker#</td>
									<td class="lineNumber">#i#</td>
									<td class="lineOccur"><cfif (journalLine.RecordCount > 0)>#journalLine.RecordCount#</cfif></td>
									<td class="#codeClass#"><pre>#src[i].code#</pre></td>
								</tr>
							</cfoutput>
						</cfloop>
					</table>
				</div>
			</div>
			</cfsavecontent>
			<cfreturn theTable>

		</cffunction>


<!---
/**
  * @public
  * @method getHitLineCount
  * @param {any} _journal (required)
  * @param {any} _fileId (required)
  * @param {any} _jLineStart
  * @param {any} _jLineEnd
  */
--->
<cffunction name="getHitLineCount" access="public" returntype="Any">
	<cfargument name="_journal" required="true">
	<cfargument name="_fileId" required="true">
	<cfargument name="_jLineStart" required="false" default=0>
	<cfargument name="_jLineEnd" required="false" default=0>
	<cfscript>
		var lbf = CacheGet('lbf' & arguments._fileId);

		if ( isSimpleValue(lbf) ) {
			lbf = this.linesByFile( _idx = arguments._fileId, lineStart = arguments._jLineStart, lineEnd = arguments._jLineEnd );
			cacheput('lbf' & arguments._fileId, lbf);
		}

		var srcObj = this.getSource( arguments._fileId );
		//get the lines of source code
		var src = srcObj.getSourceLines();

		var ret = 0;

		for (i=1;i LTE arrayLen(src);i=i+1) {
			var journalLines = queryOfQueryRun("SELECT * FROM lbf WHERE line=#i# ORDER BY journalid");
			if ( journalLines.recordCount > 0 ) {
				ret += journalLines.recordCount;
			}
		}
		return ret;
	</cfscript>
</cffunction>


</cfcomponent>