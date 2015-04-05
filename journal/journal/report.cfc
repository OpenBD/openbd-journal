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
<cfcomponent output="false">
<!---	
/**
	* @Class journaling.journal.report
	* @version $Id: report.cfc 2522 2015-02-19 23:14:55Z wpultz $
	*/

/**
	* Creates a heatmap markup
	*
  * @public
  * @method renderTreeHeatMapMarkup
  * @param {numeric} {numeric} [width = 960]
  * @param {numeric} {numeric} [height = 500]
  * @return {string}
  */
--->
<cffunction name="renderTreeHeatMapMarkup" access="public" returntype="string">
	<cfargument name="width" type="numeric" required="false" default="960">
	<cfargument name="height" type="numeric" required="false" default="500">

	<cfset var ret = "">

	<cfsavecontent variable="ret">
		<form style="margin-bottom: 1em">
			<label>The blocks below will be sized relative to <select name="mode" id="mode">
				<option value="nSource" selected="selected">Total count of all CFML Source lines</option>
				<option value="nTag">Count of all CFML Tag lines</option>
				<option value="nScript">Count of all CFML Script lines</option>
				<option value="nComments">Count of all CFML Comment lines</option>
				<option value="nBlank">Count of all Blank lines</option>
				<option value="nOther">Count of all Other lines</option>
				<option value="nCoverage">Coverage Amount</option>
				<option value="normalize">Normalized all blocks to the same size</option>
			</select> in a given source file (*.cfm, *.cfc, *.inc)</label>
		</form>
		<cfoutput><div id="heatmapLoading"><img src="assets/img/loading.gif" /></div><svg id="treeHeat" width="#arguments.width#" height="#arguments.height#"></svg></cfoutput>
	</cfsavecontent>

	<cfreturn ret>

</cffunction>



<!---
/**
	* Creates a treemap markup
	*
  * @public
  * @method renderTreeHeatMapMarkup
  * @param {numeric} {numeric} [width = 800]
  * @param {numeric} {numeric} [height = 800]
  * @return {string}
  */
--->
<cffunction name="renderTreeMapMarkup" access="public" returntype="string">
	<cfargument name="width" type="numeric" required="false" default="800">
	<cfargument name="height" type="numeric" required="false" default="800">

	<cfset var ret = "">

	<cfsavecontent variable="ret">
		<cfoutput><svg id="treeMap" width="#arguments.width#" height="#arguments.height#"></svg></cfoutput>
	</cfsavecontent>

	<cfreturn ret>

</cffunction>



<!---
/**
	* Renders heapkeys
	*
  * @public
  * @method renderHeapKey
  * @param {numeric} {numeric} [width = 400]
  * @param {numeric} {numeric} [height = 40]
  * @return {string}
  */
--->
<cffunction name="renderHeapKey" access="public" returntype="string">
	<cfargument name="width" type="numeric" required="false" default="400">
	<cfargument name="height" type="numeric" required="false" default="40">
	<cfset var ret="">

	<cfsavecontent variable="ret"><cfoutput>
		<div id="treeKey" style="position: relative; height: #arguments.height+50#px; width: #arguments.width#px">
		<div style="text-align:center">Box Color indicates Code Coverage</div>
		<svg width="#arguments.width#" height="#arguments.height#">
			<defs>
				<linearGradient id="coverageScale">
					<stop offset="5%"  stop-color="rgb(255,0,0)"/>
					<stop offset="95%" stop-color="rgb(0,0,255)"/>
				</linearGradient>
			</defs>
			<rect fill="url(##coverageScale)" x="0" y="0" width="#arguments.width#" height="#arguments.height#" />
			<div style="position: absolute; top:#arguments.height+25#px; left:0px;">0% Coverage</div>
			<div style="text-align:center; position: absolute; top:#arguments.height+25#px; left:#arguments.width/2-30#px;">50% Coverage</div>
			<div style="text-align:right; position: absolute; top:#arguments.height+25#px; right:0px;">100% Coverage</div>
		</svg>
	</div>
	</cfoutput></cfsavecontent>
	<cfreturn ret>
</cffunction>


</cfcomponent>