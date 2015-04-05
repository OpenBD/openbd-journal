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
	  * $Id: source.cfc 2522 2015-02-19 23:14:55Z wpultz $
	  *
	  * @class journal.source
	  */

	this.fHash = "";
	this.bHashSync = true;
	this.aSource = [];
	this.uStats = {	nBlank:0,
									nComments:0,
									nSource:0,
									nTag:0,
									nScript:0,
									nOther:0,
									nCoverage:0};


	/**
	  * initialize this object
	  *
	  * @method init
	  * @public
	  * @param {string} _sPath (required)
	  * @return {component} this
	  */
	public component function init(required string _sPath, string sHash=""){
		var fObj = fileOpen(_sPath,"read");

		//get the MD5 hash for the file
		this.fHash = hashBinary(_sPath,"MD5");

		//if the hash was passed, check if the MD5s match
		if (len(trim(arguments.sHash)) > 0){
			//MD5 do not match, the file we opened is not the same one we expected
			this.bHashSync = (this.fHash == arguments.sHash);
		}

		//loop over the content of the file
		while (!fileIsEOF(fObj)){
			var uLine = {code:"",blank:true};
			//save the source content
			uLine.code = fileReadLine(fObj);
			//check if the line is blank
			uLine.blank = (len(trim(uLine.code))==0);

			//update stats for blank lines
			if (uLine.blank){
				this.uStats.nBlank++;
			} else {
				this.uStats.nOther++;
			}
			//default the content of the line for later flaging
			uLine.content = "";

			//save the line to an array
			arrayAppend(this.aSource,uLine);
		}

		//parse the comments
		this.parseComments();
		//basic parsing the syntax
		this.parseSyntax();

		//close the file
		fileClose(fObj);

		return this;
	}



	/**
	  * parse the comment in the source file.  supports nested comments
	  * 	CB: Comment Begin (Multiline)
	  * 	C: Comment (Multiline)
	  * 	CE: Comment End (Multiline)
	  * 	CC: Single Line Comment
	  *
	  * @method parseComments
	  * @private
	  */
	private void function parseComments(){
		var multiLine = false;
		var type = "";

		//loop over all the lines
		for (var i=1; i <= arrayLen(this.aSource); i++){
			uLine = this.aSource[i];

			//if we are working with a multiline comment, we have different rules
			if (multiLine){
				//check for closing comment marker, depending on the style of comment
				if (type == "script" && reFind(".*?\*/.*", uLine.code)>0 ||
						type == "tag" && reFind(".*?-{3}>.*", uLine.code)>0){
					//flag the line as a ending comment, and clear the multiline flag
					this.uStats.nComments++;
					this.uStats.nOther--;
					uLine.content = "CE";
					multiLine = false;
				} else {
					//still working on a multiline comment, continue on
					this.uStats.nComments++;
					this.uStats.nOther--;
					//blank lines within a comment block get counted as comments, not blank lines for stats
					if (uLine.blank){
						this.uStats.nBlank--;
					}
					uLine.content = "C";
				}
			} else if (!uLine.blank) {
				//check for different types of single line comments
				if (reFind(".*//.*", uLine.code)>0 ||
						reFind("\n\s*\*", uLine.code)>0 ||
						reFind(".*/\*.*?\*/.*", uLine.code)>0 ||
						reFind(".*<!-{3}.*?-{3}>.*", uLine.code)>0){

					//check to see if we have content before the comment
					if ( reFind(".*\w.*//", uLine.code)==0 ) {
						//no content before the comment, continue on
						this.uStats.nComments++;
						this.uStats.nOther--;
						uLine.content = "CC";
					}
				} else if (reFind(".*<!-{3}.*?", uLine.code)>0){
					//we have a multiline tag style comment
					this.uStats.nComments++;
					this.uStats.nOther--;
					uLine.content = "CB";
					multiLine = true;
					type = "tag";
				} else if (reFind(".*/\*.*?", uLine.code)>0){
					//we have a multiline script style comment
					this.uStats.nComments++;
					this.uStats.nOther--;
					uLine.content = "CB";
					multiLine = true;
					type = "script";
				}
			}
		}
	}



	/**
	  * parse the syntax in the source file. provides basic information about the syntax on the line
	  * 	TB: Tag Being (multiline)
	  * 	TM: Tag Continue (multiline)
	  * 	TE: Tag End (multiline)
	  * 	TT: Tag Statement
	  * 	SB: Script Begin (Multiline)
	  * 	SC: Script Continue (Multiline)
	  * 	SE: Script End (multiline)
	  * 	SS: Script Statement
	  *
	  *
	  * @method parseComments
	  * @private
	  */
	private void function parseSyntax(){
		var scriptBlock = false;
		var multiLine = false;
		for (var i=1; i <= arrayLen(this.aSource); i++){
			uLine = this.aSource[i];

			//we don't care about blank lines, or comments
			if (!uLine.blank && uLine.content == ""){
				//if we are in a script block, differnt parsing rules
				if (scriptBlock){
					//check if we have a close script tag to return to tag syntax
					if (reFind("</cfscript>",uLine.code)){
						//close out the tag
						uLine.content = "TE";
						this.uStats.nTag++;
						scriptBlock = false;
					} else { //still in script syntax

						//do we have a line terminator...won't work for multiline JSON declarations
						var lineTerm = reFind(";|{", uLine.code);
						uLine.content = "S";

						//if we are working on a multiline statemnt
						if (multiLine){
							//check if we can close it
							if (lineTerm > 1){
								uLine.content &= "E";
								multiLine = false;
							} else {
								//continue the multiline
								uLine.content &= "C";
							}
						} else {

							if (lineTerm > 1){
								//we are on a single line statement
								uLine.content &= "S";
							} else {
								//we are starting a multitline statment
								multiline = true;
								uLine.content &= "B";
							}
						}
						this.uStats.nScript++;
					}
					this.uStats.nSource++;
					this.uStats.nOther--;

				} else {
					if (multiLine){
						//we are on a multiline statment, check for a terminator...won't work for complex logic statments that involve >
						var tagSearch = reFind("(.*?)(>)?$",uLine.code,1,true);
						if (arrayLen(tagSearch.pos)>=3 && tagSearch.pos[3]>=1){
							//close ouf the multiline tag
							uLine.content = "TE";
							multiLine = false;
						} else {
							//keep going with the multiline tag
							uLine.content = "TM";
						}
						this.uStats.nOther--;
						this.uStats.nSource++;
					} else {
						//get the basics of the tag, and see if it terminates
						var tagSearch = reFind("</?cf(\w*)(.*?)(>)?$",uLine.code,1,true);


						if (arrayLen(tagSearch.pos)>1 && tagSearch.pos[1]>=1){
							//we found a tag, now get the tag name (need to check for cfscript)
							tag = mid(uLine.code,tagSearch.pos[2], tagSearch.len[2]);
							//check to see if this statment closes on the same line
							if (tagSearch.pos[4]>1 && tagSearch.pos[4]>1){
								uLine.content = "TT";
							} else {
								//we are starting a multiline statement
								multiline = true;
								uLine.content = "TS";
							}
							this.uStats.nOther--;
							this.uStats.nSource++;
							this.uStats.nTag++;

							//see if we started a cfscript block for seperate parsing
							if (tag == "script" || reFind("<cfscript>",uLine.code)){
								scriptBlock = true;
							}
						}
					}
				}
			}
		}
	}


	/**
	  *
	  *
	  *
	  * @method getSourceLines
	  * @public
	  * @return {array} source lines
	  */
	public array function getSourceLines(){
		return this.aSource;
	}



</cfscript></cfcomponent>