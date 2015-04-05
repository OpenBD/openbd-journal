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

  $Id: compound.cfc 2522 2015-02-19 23:14:55Z wpultz $
--->

<cfcomponent output="false" hint="Single purpose component, takes a number of journal files and writes a compound journal file to disk">
	<!---
	/**
		* Entry point for the compound component
		* 
		* @Class journaling.journal.compound
		* @author mfernstrom
	  *
	  * @public
	  * @method compoundJournals
	  * @param {string} _files (required)  Takes a list of names, relative to the journal log root
	  * @param {string} [_filename = ""] If you pass in a filename, that will be used when saving the compound journal file
	  * @return {struct} returns a struct containing _success and _message, _success is a boolean and _message contains any error message
	  */
	--->
<cffunction name="compoundJournals" access="public" hint="Entry point for the compound component">
		<cfargument name="_files" 		type="string" required="true" hint="Takes a list of names, relative to the journal log root">
		<cfargument name="_filename" 	type="string" default="" 			hint="If you pass in a filename, that will be used when saving the compound journal file">
		<cfscript>
			try {
				// Setting up new object to browser component
				this.brs = new browser();
				
				// Making an array of the files list, and sorting
				// so we're compounding in the right order.
				var theList = listToArray(arguments._files);
				arraySort(theList, 'text');

				// Setting up the compStruct we'll be using for the compound journal file
				var compStruct 							= {};
						compStruct._uri 				= '';
						compStruct._bytes				= 0;
						compStruct._method			= 0;
						compStruct._querycount	= 0;
						compStruct._querytime		= 0;
						compStruct._timems			= 0;

				// Setting up some defaults and helpers.
				this.endLine 			= '';
				var theFile 			= '';
				var filesInThis		= '';
				var tempRest 			= '';
				var blockToAppend = '';
				var timeOffset 		= 0;
				var journalFiles	= [];

				// If no filename was specified, give it a name containing a random trailing number
				if ( Len(arguments._filename) == 0 ) {
					arguments._filename = 'compound' & randrange(1,10000) & '.txt';
				}

				// Creating a file list from all the journal files
				for ( item in theList ) {
					jrnl = this.brs.getJournal( GetJournalDirectory() & '/' & item );
					for ( i = 1; i <= ArrayLen(jrnl.files); i++ ) {
						if ( !arrayContains(journalFiles, jrnl.files[i]) ) {
							arrayAppend(journalFiles, jrnl.files[i]);
						}
					}
				}
				
				// Looping each journal file
				for ( f in theList ) {
					theFile = fileRead( GetJournalDirectory() & '/' & f );
					compStructTemp = getStructFromJournal( f );

					// Setting the uri and method based on the first journal file
					if ( Len(compStruct._uri) == 0 ) {
						compStruct._uri 		= compStructTemp._uri;
						compStruct._method	= compStructTemp._method;
					}

					// compStruct is the new header for the compounded journal file,
					// so we're just updating the numbers as we go, making sure the compound file
					// matches the combined journals.
					compStruct._bytes				+= compStructTemp._bytes;
					compStruct._querycount	+= compStructTemp._querycount;
					compStruct._querytime		+= compStructTemp._querytime;
					compStruct._timems			+= compStructTemp._timems;

					// Separating the struct from the rest of the file
					tempRest = ListRest( theFile, chr(10) & chr(13) );

					// Creating the blockToAppend, adding newlines and whatnot.
					blockToAppend = blockToAppend & chr(10) & fixBlock( _files = journalFiles,
																															_block = tempRest,
																															_filename = f,
																															_timeOffset = timeOffset );

					// Setting the timeOffset for the next loop iteration
					timeOffset += compStructTemp._timems;
				} // End for loop

				// Clean up old test file, if needed.
				if ( fileExists(GetJournalDirectory() & '/' & 'testcompound.txt') ) {
					fileDelete(GetJournalDirectory() & '/' & 'testcompound.txt');
				}
				// Setting up the new header
				headerToReturn = structCopy( this.arrToStr(journalFiles));
				structAppend(headerToReturn, compStruct);
				var fixedNewComp = serializejson( headerToReturn );
				fixedNewComp = replace(fixedNewComp, fileSeparator() & fileSeparator(), '/', "ALL");

				// Fixing this.endline to match up to overall file ms count.
				// this.endLine = headerToReturn._timems & Right(this.endLine, Len(this.endLine) - 1);
				this.endLine = headerToReturn._timems & ',' & listRest(this.endLine);

				// Writing the result to file
				FileWrite( GetJournalDirectory() & '/' & arguments._filename, fixedNewComp & blockToAppend) ;
				
				return { "_success":true, "_message":"" };
			} catch ( any e ) {
				writeDump(e);
				console(e);
				abort;
				return { "_success":false, "_message": e };
			}
		</cfscript>
	</cffunction>

	

	<!---
	/**
	  * Turns an array into a struct with the index as the value
	  *
	  * @private
	  * @method arrToStr
	  * @param {array} arr (required) 
	  * @return 
	  */
	--->
<cffunction name="arrToStr" access="private" hint="Turns an array into a struct with the index as the value">
		<cfargument name="arr" required="true" type="array">
		<!--- Self explanatory code --->
		<cfset var t = {}>
		<cfloop from="1" to="#arrayLen(arguments.arr)#" index="i">
			<cfset t[arguments.arr[i].name] = { "id" : i, "hash" : arguments.arr[i].hash }>
		</cfloop>
		<cfreturn t>
	</cffunction>



	<!---
	/**
		* Takes the non-json block and fixes timestamps and file references
		*
	  * @private
	  * @method fixBlock
	  * @param {array} _files (required) 
	  * @param {string} _block (required) 
	  * @param {string} _filename (required) 
	  * @param {numeric} _timeOffset (required) 
	  * @return 
	  */
	--->
<cffunction name="fixBlock" access="private" hint="Takes the non-json block and fixes timestamps and file references">
		<cfargument name="_files" 			type="array" 		required="true">
		<cfargument name="_block" 			type="string" 	required="true">
		<cfargument name="_filename" 		type="string" 	required="true">
		<cfargument name="_timeOffset" 	type="numeric" 	required="true">
		<cfscript>
			var jrnl = this.brs.getJournal( GetJournalDirectory() & '/' & arguments._filename );
			var fileList = {};

			// File list
			for ( i=1; i <= arrayLen(arguments._files); i++ ) {
				fileList[structKeyList(arguments._files[i])] = i;
			}

			// Turn the non-json into an array
			var toFix = listToArray(arguments._block, chr(13)&chr(10));

			// Instead of creating a new array with modified data, we just modify the existing one
			if ( isArray(toFix) ) {
				for ( i = 1; i <= ArrayLen(toFix); i++ ) {
					if ( IsNumeric(listGetAt(toFix[i], 3)) ) {
						toFix[i] = ListSetat( toFix[i], 3, arrayFind(arguments._files, jrnl.files[listGetAt(toFix[i], 3)]) );
					}
					toFix[i] = ListSetat( toFix[i], 1, ListFirst( toFix[i] ) + arguments._timeOffset );
				}			
			}
			// And return a list rather than array
			return ArrayToList(toFix, chr(10));
		</cfscript>
	</cffunction>



	<!---
	/**
	  * Returns the json block as a struct for the specified file
	  *
	  * @public
	  * @method getStructFromJournal
	  * @param {string} _journal (required) 
	  */
	--->
<cffunction name="getStructFromJournal" access="public" hint="Returns the json block as a struct for the specified file">
		<cfargument name="_journal" type="string" required="true">
		<cfscript>
			try {
				var file = fileRead( GetJournalDirectory() & fileSeparator() & arguments._journal );
				file = replace( file, '\', '/', "ALL" );
				return DeSerializeJson( listFirst( file, chr(10) & chr(13) ) & '}' );
			} catch( any e ) {
				console(e);
				writedump(e);
			}
		</cfscript>
	</cffunction>
</cfcomponent>