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

<cfsilent><cfscript>
	/**
		* @Class journaling.coverage
		*/
	title = 'Journal Coverage';

	param name="URL.mode" default="nSource";
	if ( !structKeyExists( url, "journal" ) ) {
		location( "index.cfm" );
	}
	journalPath = GetJournalDirectory() & url.journal;

	try {
		journal = new journal.parser( journalPath );
		journal.loadAll();
		totalCoverage = int( journal.getTotalCoverage() * 1000 ) / 10;
		coverageDonut = {	"Coverage":	{ "value":totalCoverage,			color:"##219CD0" },
											"Gap":			{ "value":100-totalCoverage,	color:"##0B3A4C" } };
		totalStats = journal.getTotalStats();
		stateFriendly = {
			nBlank 		: "Blank Lines",
			nComments : "Comment Lines",
			nSource 	: "Source Code",
			nTag 			: "CFML Tag",
			nScript 	: "CFScript",
			nOther 		: "Other"
		};
		statDonut = {};
		for ( stat in totalStats ) {
			if ( listFind( "nSource,nCoverage", stat ) < 1 ) {
				statDonut[ stateFriendly[ stat ] ] = { value : totalStats[ stat ] };
			}
		}
		tagStats = journal.getTagUsage();
		tagDonut = {};
		for ( tag in tagStats ) {
			tagDonut[ tag.tag ] = { value : tag.cnt };
		}
		rpt = new journal.report();

		donutFactory = new journal.donut();
	} catch( any err ) {
		console( "error encountered in coverage.cfm" );
		console( err );
	}
</cfscript></cfsilent>

<cfinclude template="header.cfm">

	<cfif IsDefined( "rpt" )>

		<cfoutput>

		<div class="pure-g" style="min-width: 980px">

			<div class="tabs-container pure-u-1 pure-u-lg-20-24">
				<ul class="tabs">
					<li class="pure-button pure-button-primary large" data-id="1">Coverage by Directory</li>
					<li class="pure-button large" data-id="2">Coverage Heat Map</li>
				</ul>
			</div>

			<div id="tab1" class="pure-u-2-3 pure-u-lg-11-24 tabbed">
				<h3>Coverage by Directory</h3>
				<svg id="treeMap" width="600" height="600"></svg>
				#rpt.renderHeapKey(500,10)#
			</div>

			<div id="tab2" class="pure-u-2-3 pure-u-lg-11-24 tabbed">
				<h3>Coverage Heat Map</h3>
				#rpt.renderTreeHeatMapMarkup(600,400)#
			</div>

			<div id="files-list" class="pure-u-1-3 pure-u-lg-9-24">
				<h3>Files touched in this Journal</h3>
				<ul class="coverage_list">
				<cfloop from="1" to="#arrayLen( journal.getFiles() )#" index="f">
					<li><a id="file_#f#" href="fileCoverage.cfm?journal=#journal.relativeToJournal#&file=#f#">#journal.getPrettyFile( f )#</a> <span style="white-space: nowrap">( #int( journal.getCoverage( f ) * 1000 ) / 10#% )</span></li>
				</cfloop>
				</ul>
			</div>

			<div id="donuts" class="pure-u-1 pure-u-lg-4-24">
				#donutFactory.donut( _data = coverageDonut, _settings = { "display" : "value", "showKeys" : false , header: "Code Coverage"} )#
				#donutFactory.donut( _data = statDonut, _settings = { "display" : "value", "showKeys" : false, header: "Line Breakdown" } )#
			</div>

		</div>

		</cfoutput>

		<script type="text/javascript" src="assets/js/vendor/d3.geom.js"></script>
		<script type="text/javascript" src="assets/js/vendor/d3.layout.js"></script>
		<script src="assets/js/journal/tree-heat-map.js"></script>
		<script src="assets/js/journal/tree-map.js"></script>

		<script>
		$( function() {
		  var uState = <cfoutput>#serializeJSON( object = URL, conv = "upper" )#</cfoutput>;

		  treeHeatMap = new TreeHeatMap( '<cfoutput>#url.journal#</cfoutput>', '#treeHeat', uState );
		  treeMap = new TreeMap( '<cfoutput>#url.journal#</cfoutput>', '#treeMap' );

		  var color = '';

		  $( '#mode' ).val( uState.MODE ).trigger( 'change' );

		  $( '[id^=file_]' ).on( 'mouseover', function() {

		    var fileId = $( this ).attr( 'id' ).split( '_' )[ 1 ];
		    $( '#heat_' + fileId ).attr( 'heatcolor', $( '#heat_' + fileId ).attr( 'fill' ) )
		    	.attr( 'fill', '#11465B' ).attr( 'stroke', '#EFC10A' ).attr('stroke-width','2px');

		  } ).on( 'mouseout', function() {

		    var fileId = $( this ).attr( 'id' ).split( '_' )[ 1 ];
		    $( '#heat_' + fileId ).attr( 'fill', $( '#heat_' + fileId ).attr( 'heatcolor' ) )
		    	.attr( 'stroke', '#c6dbef' ).attr('stroke-width','');

		  } );


		  function heatClick( _d ) {
		    if ( _d.file_id != -1 ) {
		      uState.FILE = _d.file_id;

		      window.open( 'fileCoverage.cfm?JOURNAL=' + uState.JOURNAL + '&FILE=' + uState.FILE );
		    }
		  }

		  // Gets donut data, sets callback handler, since we don't handle the donuts exactly the same
		  getDonutData = function( i, u, type ) {
		    var jscfcInst = new parsercfc();
		    if ( arguments[ 2 ] == 'coverage' ) {
		      jscfcInst.setCallbackHandler( displayCoverageDonut );
		    }
		    else {
		      jscfcInst.setCallbackHandler( displayBreakdownDonut );
		    }
		    jscfcInst.ajaxGetInfo( i, u, type );
		  };

		  // Shapes the data before actually sending it off to create and insert a donut
		  displayBreakdownDonut = function( i ) {
		    var theData = '';
		    for ( item in i.DATA ) {
		      theData = theData + ',"' + i.DATA[ item ][ 0 ] + '":{"value":"' + i.DATA[ item ][ 1 ] + '"}';
		    }
		    getDonut( data = theData.substr( 1 ), settings = '"header":"Code Breakdown", "showKeys":false', div = 'source1stat' );
		  };

		  // Shapes the data before actually sending it off to create and insert a donut
		  displayCoverageDonut = function( i ) {
		    var theData = '"Coverage":{"value":"' + i.a + '","color":"#219CD0"},"Gap":{"value":"' + i.b + '","color":"#0B3A4C"}';
		    getDonut( data = theData,
		      settings = '"header":"Code Coverage", "showKeys":false, "display":"percentage"',
		      div = 'source1coverage' );
		  };

		  // Pass it data, it ajaxes a donut and inserts it into the target div
		  getDonut = function( data, settings, div ) {
		    $( '#' + div ).load( 'journal/donut.cfc?METHOD=donut&_data={' + escape( data ) + '}&_settings={' + escape( settings ) + '}' );
		  };

		  // tab functionality
		  var legend = $( '#treeKey' );

			function switchTabs( e ) {
			  $( '.tabbed' ).hide();
			  var active = $( '#tab' + $( '.tabs .pure-button-primary' ).data( 'id' ) );
			  active.show();
			  if ( !$.contains( active[ 0 ], legend[ 0 ] ) ) {
			    legend.detach().appendTo( active );
			  }
			}
			switchTabs();

			$( '.tabs' ).on( 'click', 'li', function( e ) {
			  $( '.tabs li' ).removeClass( 'pure-button-primary' );
			  $( this ).addClass( 'pure-button-primary' );
			  switchTabs();
			} );

		} );
		</script>

	<cfelse>

		<p>An error was encountered while reading this journal file. Please return to the <a href="index.cfm">Journaling Home Page</a> and select another journal.</p>

	</cfif>

<cfinclude template="footer.cfm">