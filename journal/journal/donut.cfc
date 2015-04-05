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

  $Id: donut.cfc 2522 2015-02-19 23:14:55Z wpultz $
--->

<cfcomponent output="false" hint="I'm the donut factory. Toss me data and I'll throw back donuts.">
	<!---
			_data takes a struct with the following format:
				_data = {"Blank":{"value":9},"Comments":{"value":4},"Other":{"value":19, "color":"#2A7FFC"}}

				Note that color is optional, if you don't include a variable for color, one will be chosen at random,
				if you specify a color, it will be used.

			_settings is optional
			_settings.display can be either value or percentage
			_settings.showKeys is a boolean
			_settings.size takes a list of width and height: "200,300"
			_settings.left is a boolean, defining if the donut should be on the left or right side.

			'showKeys' turns on or off the legend, 'display' switches between showing
			the absolute value or a relative percentage in the legend

			The only required library is D3.
		
	/**
		* @Class journaling.journal.donut
		* @author mfernstrom
		*/

	/**
	  * Main entry point for the donut factory
	  *
	  * @remote
	  * @method donut
	  * @param {any} _data (required)  Takes a struct of values, see example file.
	  * @param {any} _settings Optional with some defaults, see example file
	  * @returnformat {plain}
	  * @return 
	  */
	--->
<cffunction name="donut" access="remote" hint="Main entry point for the donut factory" returnformat="plain">
		<cfargument name="_data" required="true" hint="Takes a struct of values, see example file.">
		<cfargument name="_settings" default='{}' hint="Optional with some defaults, see example file">
		<cfscript>
			// In case we're using the default for settings 
			if ( !isStruct(arguments._data) )			{ arguments._data 		= deserializeJSON(arguments._data); }
			if ( !isStruct(arguments._settings) )	{ arguments._settings	= deserializeJSON(arguments._settings); }

			// Ensuring that options are still optional, even when the user passes in _settings
			if ( !structKeyExists(arguments._settings, 'size') ) 			{ arguments._settings.size 			= '150,150'; }
			if ( !structKeyExists(arguments._settings, 'showKeys') ) 	{ arguments._settings.showKeys 	= true; }
			if ( !structKeyExists(arguments._settings, 'display') ) 	{ arguments._settings.display 	= 'value'; }
			if ( !structKeyExists(arguments._settings, 'left') ) 			{ arguments._settings.left 			= true; }

			// Helper contains the color generator
			var helper = createObject('component','helpers');
			var colors = helper.getColors( structCount(arguments._data) );

			// Setting a random ID, starting with A because if it starts with a number, it breaks.
			var id = 'A' & Replace(createUUID(), '-', '', 'ALL');

			// Setting some defaults
			var total 					= 0;
			var list 						= [];
			var last 						= 0;
			var counter 				= 1;
			var data 						= {};
			var totalForPercent	= 0;
			var toReturn				= '';
			var useColor 				= '';
			var key 						= '';

			// If setting is percentage, we need to do a little math
			if ( arguments._settings.display == 'percentage' ) {
				for ( item in arguments._data ) {
					totalForPercent = totalForPercent + arguments._data[item].value;
				}
			}

			// If showKeys is true, we prepare the data set for display
			if ( arguments._settings.showKeys ) {
				// Setting up for later displaying values
				for ( item in arguments._data ) {
					if ( arguments._settings.display == 'value' ) {
						data[item] = arguments._data[item].value;
					} else {
						data[item] = numberFormat( (arguments._data[item].value / totalForPercent) * 100, '0_' ) & '%';
					}
				}
			}

			// Setting up data used in donut & legend
			for ( item in arguments._data ) {
				if ( structKeyExists(arguments._data[item], 'color') ) {
					if (left(arguments._data[item].color, 1) == '##' ) {
						useColor = arguments._data[item].color;
					} else {
						useColor = "##" & arguments._data[item].color;
					}
				} else {
					useColor = colors[counter];
				}

				arrayAppend(list, [	last,
														last + arguments._data[item].value,
														useColor,
														item,
														arguments._data[item].value ]);
				last 		+= arguments._data[item].value;
				total 	+= arguments._data[item].value;
				counter++;
			} // End for loop
		</cfscript>
		<!--- Prepare html donut to be returned --->
		<cfsavecontent variable="toReturn">
		<cfoutput>
			<div class="donutWrapper" style="<!--- max-width: #Trim(ListRest(arguments._settings.size)) * 2#px; min-height: #ListRest(arguments._settings.size)+80#px; --->">
				<cfif structKeyExists(arguments._settings, "header")><h3>#arguments._settings.header#</h3></cfif>
				<cfif Len(structKeyList(arguments._data)) == 0 >No data</cfif>
					<cfif arguments._settings.showKeys AND !arguments._settings.left>
						<div class="fltLeft">
							<cfset counter = 1>
							<cfloop list="#structKeyList(arguments._data)#" index="key">
								<cfif arguments._settings.showKeys == true>
									<span style="background:#list[counter][3]#;">&nbsp;&nbsp;&nbsp;&nbsp;</span> #data[key]# - #key#<br>
								</cfif>
								<cfset counter++>
							</cfloop>
						</div>
					</cfif>
				<div class="fltLeft">
					<cfif arguments._settings.showKeys AND arguments._settings.left>
						<div class="fltRight">
							<cfset counter = 1>
							<cfloop list="#structKeyList(arguments._data)#" index="key">
								<cfif arguments._settings.showKeys == true>
									<span style="background:#list[counter][3]#;">&nbsp;&nbsp;&nbsp;&nbsp;</span> #data[key]# - #key#<br>
								</cfif>
								<cfset counter++>
							</cfloop>
						</div>
					</cfif>
					<cfif Len(structKeyList(arguments._data)) != 0 >
						<svg id="#id#" width="#Trim(ListFirst(arguments._settings.size))#" height="#Trim(ListRest(arguments._settings.size))#"></svg>
					</cfif>
				</div>
			</div>
			<script>
			(function(){
				var tip = d3.tip().attr('class', 'd3-tip').direction("se")
								.html(function(d){	return d[3] + ": " + d[4]<cfif arguments._settings.display == "percentage"> + '%'</cfif>});
				var vis#id# = d3.select("###id#");
				var data#id# = #serializeJSON(list)#;
				// console.log(data#id#);
				var cScale#id# = d3.scale.linear().domain([0, #total#]).range([0, 2 * Math.PI]);
				var arc#id# = d3.svg
												.arc()
												.innerRadius(#Trim(ListFirst(arguments._settings.size)) / 4#)
												.outerRadius(#Trim(ListFirst(arguments._settings.size)) / 2#)
												.startAngle(function(d){ return cScale#id#(d[0]); })
												.endAngle(function(d){ return cScale#id#(d[1]); });
				vis#id#.call(tip)
								.selectAll("path")
								.data(data#id#)
								.enter()
									.append("path")
									.attr("d", arc#id#)
									.style("fill", function(d){return d[2];})
									.attr("transform", "translate(#Trim(ListFirst(arguments._settings.size))/2#,#Trim(ListFirst(arguments._settings.size))/2#)")
									.on('mouseover', tip.show)
									.on('mouseout', tip.hide);
			})();
			</script>
		</cfoutput>
		</cfsavecontent>
		<cfreturn toReturn>
	</cffunction>
</cfcomponent>