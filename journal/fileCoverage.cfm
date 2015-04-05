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
		* $Id: fileCoverage.cfm 2522 2015-02-19 23:14:55Z wpultz $
		* 
		* @Class journaling.fileCoverage
		*/
	title = 'Journaling File Coverage';

	param name="URL.mode" default="nSource";
	if ( !structKeyExists( url, "journal" ) ) {
		location( "index.cfm" );
	}

	try {
		// Set up some defaults
		parser = new journal.parser( GetJournalDirectory() & url.journal );
		file1name = parser.getPrettyFile( _idx = url.file, _journal = url.journal );
		source = parser.getSource( url.file );
	} catch( any err ) {
		console( err );
	}
</cfscript></cfsilent>

<cfinclude template="header.cfm">

	<cfif IsDefined( "parser" )>

		<cfoutput>
		<!--- <h2>Journal: <a href="coverage.cfm?journal=#url.journal#">#url.journal#</a> &nbsp;|&nbsp; File: #file1name#<span id="fileName"></span></h2> --->

		<cfif ( !source.bHashSync )>
		<div class="syncWarning">
			<h3 class="warning"><cfoutput>#listLast( file1name,fileSeparator() )# is different from when it was touched by this Journal</cfoutput></h3>
			<h4 class="warning">Consider rerunning the journal for #listFirst( parser.info._uri,"?" )# before viewing the this Code Coverage report</h4>
		</div>
		</cfif>

		<div class="pure-g">
			<div class="pure-u-1">
				<div id="source1coverage"></div>
				<div id="source1stat"></div>
			</div>

			<div id="source-files" class="source-group pure-g" style="margin-top: 2em">
				<div id="source1" class="pure-u-1">Loading...<br><img src="assets/img/loading.gif" /></div>
				<div id="source2" class="pure-u-1-2"></div>
			</div>
		</div>
		</cfoutput>

		<script>
		$( function() {
			uState = <cfoutput>#serializeJSON( object=URL, conv="upper" )#</cfoutput>;

			$( '#mode' ).val( uState.MODE ).trigger( 'change' );
			$( '#mode' ).trigger( 'change' );

			function heatClick( d ) {
				if ( d.file_id != -1 ) {
					uState.FILE = d.file_id;

					history.pushState( uState, 'Coverage', '?' + $.param( uState ) );
					$( '#source1' ).load( 'journal/parser.cfc?METHOD=renderSourceCoverage&_journal=' + uState.JOURNAL + '&_file=' + uState.FILE );

					// Get data for donuts
					getDonutData( uState.JOURNAL, uState.FILE, 'coverage' );
					getDonutData( uState.JOURNAL, uState.FILE, 'breakdown' );
				}
			}

			// Triggers when user clicks on the heatmap
			var s1 = $( '#source1' ).on( 'click', 'a', function( e ) {
				e.preventDefault();
				$aTag = $( this );
				uState.FILE2 = $aTag.data( 'file' );
				uState.LINESTART2 = $aTag.data( 'linestart' );
				uState.LINEEND2 = $aTag.data( 'lineend' );
				history.pushState( uState, 'Coverage', '?' + $.param( uState ) );

				drillDown( uState );
			} );

			function drillDown( d ) {
				s1.removeClass('pure-u-1').addClass('pure-u-1-2');

				$( '#source2' ).addClass('pure-u-1-2 closeable').load( 'journal/parser.cfc?METHOD=renderSourceCoverage&_journal=' + d.JOURNAL +
					'&_file=' + d.FILE2 +
					'&_jLineStart=' + d.LINESTART2 +
					'&_jLineEnd=' + d.LINEEND2 );
			}

			if ( uState.FILE ) {
				heatClick( {
					file_id: uState.FILE
				} );
			}
			if ( uState.FILE2 ) {
				drillDown( uState );
			}

		} );

		// Ajax functions for donuts
		getDonutData = function( k, u, type ) {
			var theType = arguments[ 2 ];
			$.ajax( {
				url: 'journal/parser.cfc?METHOD=ajaxGetInfo',
				type: 'POST',
				dataType: 'JSON',
				data: {"_journal" : k, "_fileId" : u, "_type" : theType},
				success: function( d ) {
					if ( theType == 'coverage' ) {
						var theData = '"Coverage":{"value":"' + d.a + '","color":"#219CD0"},"Gap":{"value":"' + d.b + '","color":"#0B3A4C"}';
						getDonut( theData, '"header":"Code Coverage", "showKeys":false, "display":"percentage"', 'source1coverage' );
					} else {
						var theData = '';
						for ( item in d[ 'DATA' ] ) {
							theData = theData + ',"' + d[ 'DATA' ][ item ][ 0 ] + '":{"value":"' + d[ 'DATA' ][ item ][ 1 ] + '"}';
						}
						theData = theData.substr( 1 );
						getDonut( data = theData, '"header":"Code Breakdown", "showKeys":false', div = 'source1stat' );
					}
				},
				error: function( a, b, c ) {
					console.log('Something went wrong when trying to generate Donuts');
				}
			} );
		};

		// Pass it data, it ajaxes a donut and inserts it into the target div
		getDonut = function( data, settings, div ) {
			$( '#' + div ).load( 'journal/donut.cfc?METHOD=donut&_data={' + escape( data ) + '}&_settings={' + escape( settings ) + '}' );
		};
		</script>

	<cfelse>
	
		<p>An error was encountered while reading this journal file. Please return to the <a href="index.cfm">Journaling Home Page</a> and select another journal.</p>

	</cfif>

<cfinclude template="footer.cfm">