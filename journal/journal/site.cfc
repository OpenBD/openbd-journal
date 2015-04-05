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
	* @version $Id: site.cfc 2522 2015-02-19 23:14:55Z wpultz $
	* @Class journaling.journal.site
	*/
<cfcomponent output="false">
	<cfscript>
	
	// Set up some defaults
	this.root = expandPath("/").replace("\","/");
	this.fs = "/";
	this.cfExt = ["*.cfc",
								"*.cfm",
								"*.inc"];
	this.blacklist = ["journaling#fileSeparator()#",
										"mxunit#fileSeparator()#",
										"CodeChecker#fileSeparator()#",
										"WEB-INF#fileSeparator()#customtags#fileSeparator()#common"];
	this.qFiles = queryNew("name,attributes,datelastmodified,directory,mode,size,type");
	this.nFiles = 0;
	this.info = {name:"SITE",children:[]};


	/**
		* @method init
		* @public
		* @param {string} [_rootPath = "/"]  
		* @return {component}
		*/
	public component function init(string _rootPath="/"){
		var where = "";

		this.root = expandPath(arguments._rootPath).replace("\","/");

		this.qFiles = directoryList(this.root, true, "query", arrayToList(this.cfExt,"|"));

		for (var i=1; i<=arrayLen(this.blackList); i++){
			where &= "name NOT LIKE '#this.blackList[i]#%' ";
			if (i<arrayLen(this.blackList)){
				where &= "AND ";
			}
		}

		this.qFiles = queryOfQueryRun("SELECT * FROM this.qFiles WHERE #where# ORDER BY datelastmodified");
		this.nFiles = this.qFiles.recordCount;
		this.spiderHash = this.getSpiderHash();

		infoPath = "/var/tmp/24hr/" & this.spiderHash & ".json";

		if (fileExists(infoPath)){
			this.info = deserializeJSON(fileRead(infoPath));
		} else {
			this.spiderFiles();
			fileWrite(infoPath,serializeJSON(this.info));
		}

		return this;

	}


	/**
		* @method getSpiderHash
		* @private  
		* @return {string}
		*/
	private string function getSpiderHash(){
		var latest = queryOfQueryRun("SELECT max(datelastmodified) as datelastmodified FROM this.qFiles");
		var spiderString = "#this.nFiles# #latest.datelastmodified[1]#";
		return hash(spiderString);
	}


	/**
		* @method spiderFiles
		* @private  
		*/
	private void function spiderFiles(){

		for (row in this.qFiles){
			row.name = row.name.replace("\","/");
			var tName = row.name;
			var fName = listLast(tName,this.fs);
			tName = replace(tName,fName,"");
			var insPoint = this.getChild(this.info, listFirst(tName,this.fs), listRest(tName,this.fs), true);
			arrayAppend(insPoint.children,{	root:listFirst(tName,this.fs),
																			fullPath: row.name,
																			name:fName,
																			file_id:-1,
																			children:[],
																			stats:this.readFile(row.directory & this.fs & row.name)});
		}

	}


	/**
		* @method getChild
		* @private
		* @param {struct} ins (required) 
		* @param {string} first (required) 
		* @param {string} rest (required) 
		* @param {boolean} [bCreate = false]  
		* @return {struct}
		*/
	private struct function getChild(required struct ins, required string first, required string rest, boolean bCreate=false){
		if (arguments.first == ""){
			return arguments.ins;
		}

		for (var i=1; i<=arrayLen(arguments.ins.children);i++){
			if (arguments.ins.children[i].name == arguments.first){
				return this.getChild(arguments.ins.children[i], listFirst(rest,this.fs), listRest(rest,this.fs), arguments.bCreate);
			}
		}

		if (arguments.bCreate){
			var tmp = {name:arguments.first,children:[]};
			arrayAppend(ins.children,tmp);
			return this.getChild(arguments.ins.children[i], listFirst(rest,this.fs), listRest(rest,this.fs), arguments.bCreate);
		} else {
			throw("element not found #arguments.first# - #arguments.rest#");
		}
	}



	/**
		* @method readFile
		* @private
		* @param {string} _sPath (required)   
		* @return {struct}
		*/
	private struct function readFile(required string _sPath){
		var source = new source(arguments._sPath);
		return source.uStats;
	}



	/**
		* @method augmentCoverage
		* @private
		* @param {string} _sJournal (required)   
		*/
	private void function augmentCoverage(required string _sJournal){
		var journal = new parser(GetJournaldirectory() & this.fs & _sJournal);
		var files = journal.getFiles();
		for (var i=1; i<=arrayLen(files);i++){
			var reject = false;
			var fPath = journal.getPrettyFile(i);
			fPath = replace(fPath,this.fs,"","ONE");

			for (var j=1; j<= arrayLen(this.blackList); j++){
				if (left(fPath,len(this.blackList[j])) == this.blackList[j].replace("\","/")){
					reject = true;
				}
			}

			if (!reject){
				var fName = listLast(fPath,this.fs);
				var path = replace(fPath,fName,"");
				node = this.getChild(this.info, listFirst(fPath,this.fs),listRest(fPath,this.fs));
				node.stats.nCoverage = journal.getCoverage(i);
				node.file_id = i;
			}
		}
	}

	</cfscript>


	/**
		* @remote
		* @method getHeatTree
		* @param {string} {string} [rootPath = /]
		* @param {string} {string} [journal = ""]
		* @returnformat {JSON}
		* @return {struct}
		*/
	<cffunction name="getHeatTree" access="remote" returntype="struct" returnformat="JSON">
		<cfargument name="rootPath" required="false" default="/" />
		<cfargument name="journal" required="false" default="" />

		<cfset this.init( arguments.rootPath ) />
		<cfset arguments.journal = Trim( arguments.journal ) />

		<cfif Len( arguments.journal ) GTE 0>
			<cfset this.augmentCoverage( arguments.journal ) />
		</cfif>
		
		<cfreturn this.info />
	</cffunction>

</cfcomponent>