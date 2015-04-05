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
	* @version $Id: executionTree.cfc 2522 2015-02-19 23:14:55Z wpultz $
	* @Class journaling.journal.executionTree
	*/
component {

	this.sPath 			= "";
	this.journal 		= false;
	this.tree 			= [];
	this.treeDepth 	= 0;
	this.fileCount 	= 0;


	/**
		* Initialize with path to a journal
		* 
		* @method init
		* @public
		* @param {string} _sPath (required)   
		*/
	public component function init(required string _sPath){
		this.sPath = arguments._sPath;
		this.journal = new parser(this.sPath);
		this.treeDepth = this.journal.MaxFileDepth() - 1;
		this.fileCount = arrayLen(this.journal.getFiles());
	}



	/**
		* @method buildTree
		* @public
		* @param {numeric} [fileId = 1]
		* @param {numeric} [startLine = 0]
		* @param {numeric} [endLine = 0]
		* @param {numeric} [depth = 1]  
		* @return {array}
		*/
	public array function buildTree(numeric fileId=1, numeric startLine=0, numeric endLine=0, numeric depth=1){

		if (!isObject(this.journal)){
			throw("Please init this object first");
		}

		var qLines = this.journal.linesByFile(arguments.fileId,arguments.startLine,arguments.endLine);

		var current = {};
		for (var i=1; i<= qLines.recordCount; i++){
			if (structIsEmpty(current)){
				current.nFile = arguments.fileId;
				current.nBegin = qLines.journalid[i];
				current.nTimeBegin = qLines.t_offset[i];
				current.nDepth = arguments.depth;
				current.zchildren = [];
			}

			current.nEnd = qLines.journalid[i];
			current.nTimeEnd = qLines.t_offset[i];

			if (len(trim(qLines.filesBetween[i])) != 0){
				arrayAppend(this.tree,current);
				this.buildTree(listFirst(qLines.filesBetween[i]), qLines.journalid[i]+1, qLines.journalid[i+1],arguments.depth+1);
				current = {};
			}
		}

		arrayAppend(this.tree,current);

		return this.tree;

	}



	/**
		* @method getDepthData
		* @public  
		* @return {array}
		*/
	public array function getDepthData(){
		var aData = [];

		for (var i=1; i<= arrayLen(this.tree); i++){
			arrayAppend(aData, {	y: i,
														x: this.tree[i].nDepth,
														r: this.tree[i].nEnd - this.tree[i].nBegin + 1,
														f: this.tree[i].nFile,
														link:"?journal=#replace(this.sPath,GetJournaldirectory(),"")#&file=#this.tree[i].nFile#&lineStart=#this.tree[i].nBegin#&lineEnd=#this.tree[i].nEnd#",
														tip: this.journal.getPrettyFile(this.tree[i].nFile)
																	& "<br>#this.tree[i].nEnd - this.tree[i].nBegin# lines",
														accent:this.getAccent(this.tree[i])});
		}

		return aData;
	}



	/**
		* @method getIdData
		* @public  
		* @return {array}
		*/
	public array function getIdData(){
		var aData = [];
		for (var i=1;i<=arrayLen(this.tree);i++){
			arrayAppend(aData, {	y: i,
														x: int(this.tree[i].nFile),
														r: this.tree[i].nEnd - this.tree[i].nBegin + 1,
														f: this.tree[i].nDepth,
														link:"?journal=#replace(this.sPath,GetJournaldirectory(),"")#&file=#this.tree[i].nFile#&lineStart=#this.tree[i].nBegin#&lineEnd=#this.tree[i].nEnd#",
														tip: this.journal.getPrettyFile(this.tree[i].nFile)
																	& "<br>#this.tree[i].nEnd - this.tree[i].nBegin# lines",
														accent:this.getAccent(this.tree[i])});
		}
		return aData;
	}



	/**
		* @method getTimeData
		* @public  
		* @return {array}
		*/
	public array function getTimeData(){
		var aData = [];
		for (var i=1;i<=arrayLen(this.tree);i++){
			arrayAppend(aData, {	x: int(this.tree[i].nTimeBegin),
														y: int(this.tree[i].nFile),
														r: this.tree[i].nTimeEnd - this.tree[i].nTimeBegin,
														f: this.tree[i].nFile,
														link:"?journal=#replace(this.sPath,GetJournaldirectory(),"")#&file=#this.tree[i].nFile#&lineStart=#this.tree[i].nBegin#&lineEnd=#this.tree[i].nEnd#",
														tip: this.journal.getPrettyFile(this.tree[i].nFile)
																	& "<br>Time [ " & this.tree[i].nTimeBegin & " - " & this.tree[i].nTimeEnd & " ] #this.tree[i].nTimeEnd - this.tree[i].nTimeBegin#ms"
																	& "<br>Journal Lines [ " & this.tree[i].nBegin & " - " & this.tree[i].nEnd & " ]",
														accent:this.getAccent(this.tree[i])});
		}
		return aData;
	}



	/**
		* @method getAccent
		* @private
		* @param {struct} entry (required)   
		* @return {numeric}
		*/
	private numeric function getAccent(required struct entry){
		if (structKeyExists(URL,"file") && URL.file == arguments.entry.nFile){
			if (!structKeyExists(URL,"lineStart") && !structKeyExists(URL,"lineEnd") ||
					structKeyExists(URL,"lineStart") && URL.lineStart <= arguments.entry.nBegin &&
									structKeyExists(URL,"lineEnd") && URL.lineEnd >= arguments.entry.nEnd){
				return 1;
			}
		}
		return 0;
	}

}