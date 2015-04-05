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
  
	$Id: code-trace.cfm 2522 2015-02-19 23:14:55Z wpultz $

	/**
		* @Class journaling.code-trace
		*/
--->
<cfsilent><cfscript>
	title = 'Journal Performance';
	param name="url.journal" default="";

	jrnlCache = new journal.journal_cache();

	jrnl = false;
	
	try {
		jrnl = jrnlCache.getJournal( url.journal );

		// use parser to get the content of the files used during the journalled request
		parser = new journal.parser( jrnl.abspath );
		files = [];
		for ( i = 1; i <= ArrayLen( jrnl.files ); i++ ) {
			ArrayAppend( files, parser.renderSourceCoverage( i, url.journal ) );
		}

		allFrames = jrnlCache.getJournalEntries( url.journal );

		helper = new journal.helpers();
		filePathToWebRoot = expandPath("/");

		// file names for gantt chart
		for ( i = 1; i <= ArrayLen( jrnl.file_blocks ); i++ ) {
			jrnl.file_blocks[ i ].name = jrnl.files[ jrnl.file_blocks[ i ].nFile ].name;
		}

	} catch( any err ) {
		// ignore, default value of jrnl will trigger state change on the page
		console( err );
		jrnl = false;
	}
</cfscript></cfsilent>

<cfinclude template="header.cfm">

	<cfif !IsStruct( jrnl )>
		<!--- file not specified --->
		<p>No journal file was found. Please return to the <a href="index.cfm">main page</a> to select a journal.</p>

	<cfelseif !IsDefined( "parser" )>
		<!--- could not parse the file --->
		<p>An error was encountered while reading this journal file. Please return to the <a href="index.cfm">Journaling Home Page</a> and select another journal.</p>

	<cfelse>
		<!--- rock and roll, we've got everything we need --->

		<div id="controls">
			<div class="pure-g button-group">
				<button id="reload" title="Reset" class="pure-button xlarge pure-u-1-5"><i class="fa icon-ccw"></i></button>
				<button id="stepback" title="Step back" class="pure-button xlarge pure-u-1-5"><i class="fa icon-fast-bw"></i></button>
				<button id="play" title="Play" class="pure-button xlarge pure-u-1-5"><i class="fa icon-play"></i></button>
				<button id="stop" title="Pause" class="pure-button xlarge pure-u-1-5"><i class="fa icon-pause"></i></button>
				<button id="stepforward" title="Step forward" class="pure-button xlarge pure-u-1-5"><i class="fa icon-fast-fw"></i></button>
			</div>
			<div class="input-group">
				<input type="range" min="1" max="10" value="5" id="playback-speed" /></label>
				<label for="playback-speed"><span id="speed-summary">5</span> lines per second</label>
			</div>
			<div class="input-group">
				<input type="range" min="1" max="3" value="1" id="files-to-show" />
				<label for="files-to-show">Show <span id="files-shown-summary">1</span> files</label>
			</div>
			<cfif StructKeyExists( jrnl, "session_capture" ) && jrnl.session_capture>
				<label for="showSessionDump" class="pure-checkbox"><input type="checkbox" value=1 id="showSessionDump" checked /> show session data</label>
			</cfif>
		</div>

		<div style="margin-top: 50px"></div> <!--- clears the control bar --->

		<div id="source-files" class="pure-g source-group">
			<div id="var-cont"><div id="sessionVars"></div></div>
		</div>

		<div id="timeline"></div>
		<br>
		<a href="bar.cfm?journal=<cfoutput>#url.journal#</cfoutput>" class="pure-button button-secondary">Lines executed by file</a>

		<script type="text/javascript">
		$( document ).ready( function() {

			// initialize the code tracer -------------------------------------------
			// mapping of file ids to the file names
			var fileNameLookup = <cfoutput>#SerializeJSON( jrnl.files )#</cfoutput>;

			// manages the file source code preview and highlighting lines
			var fileTrace = new SourceFileTrace( fileNameLookup, 1, $( '#source-files' ) );

			// tracks the current journal line, current source file, and current line in the source file
			var context = new RequestContext( '<cfoutput>#url.journal#</cfoutput>' );

			// playback controls			
			$( '#reload' ).on( 'click', function() {
				$( document ).trigger( 'perf:gototime', { elapsedTime: 0 } );
			} );
			$( '#play' ).on( 'click', function() {
				$( '#play' ).addClass( 'pure-button-primary' );
				$( '#stop' ).removeClass( 'pure-button-primary' );
				context.play();
			} );
			$( '#stop' ).on( 'click', function() {
				$( '#stop' ).addClass( 'pure-button-primary' );
				$( '#play' ).removeClass( 'pure-button-primary' );
				context.pause();
			} );
			$( '#stepforward' ).on( 'click', function() {
				context.stepLine();
			} );
			$( '#stepback' ).on( 'click', function() {
				context.stepLineBack();
			} );
			$( '#playback-speed' ).on( 'change', function() {
				var val = $( this ).val();
				context.setPlaybackSpeed( val );
				$( '#speed-summary' ).text( val );
			} );
			$( '#files-to-show' ).on( 'change', function() {
				var val = $( this ).val();
				fileTrace.setFilesToShow( val );
				$( '#files-shown-summary' ).text( val );
			} );
			$( '#showSessionDump' ).on( 'click', function() {
				if( $( this ).is( ':checked' ) ) {
					$( '#var-cont' ).show();
				} else {
					$( '#var-cont' ).hide();
				}
				fileTrace.arrangeFiles();
			} );

			// global playback events
			$( document ).on( 'perf:stepforward', function( _e, _edat ) {
				fileTrace.stepForward( _edat );
				if ( _edat.elapsedTime ) {
					timeline.goTo( _edat.elapsedTime );
				}
				if ( _edat.session ) {
					$( '#sessionVars' ).html( _edat.session );
				}
			} );
			$( document ).on( 'perf:stepback', function( _e, _edat ) {
				fileTrace.stepBack( _edat );
				if ( _edat.elapsedTime ) {
					timeline.goTo( _edat.elapsedTime );
				}
				if ( _edat.session ) {
					$( '#sessionVars' ).html( _edat.session );
				}
			} );
			$( document ).on( 'perf:gotoline', function( _e, _edat ) {
				fileTrace.gotoLine( _edat );
				if ( _edat.session ) {
					$( '#sessionVars' ).html( _edat.session );
				}
				timeline.goTo( _edat.elapsedTime );
			} );
			$( document ).on( 'perf:gototime', function( _e, _edat ) {
				if ( _edat.elapsedTime !== false ) {
					context.gotoTimeMS( _edat.elapsedTime );
				}
			} );


			// initialize the timeline ----------------------------------------------
			var fileBlocks = <cfoutput>#serializeJSON( jrnl.file_blocks )#</cfoutput>,
			  margin = {
			    top: 0,
			    right: 0,
			    bottom: 10,
			    left: 200
			  },
			  height = Math.max( document.body.clientHeight * 0.3, 100 ),
			  width = document.getElementById( 'timeline' ).clientWidth,
			  events = {
			    'brush': function( value ) {
			      d3.selectAll( '.bar' ).classed( 'highlighted', function( d ) {
			        if ( d.nTimeBegin <= value && d.nTimeEnd >= value ) {
			          return true;
			        }
			        return false;
			      } );
			    },
			    'brushend': function( value ) {
			      $( document ).trigger( 'perf:gototime', {
			        elapsedTime: value
			      } );
			    }
			  };

			timeline = d3.layout.gantt().width( width ).height( height ).margin( margin )
			  .nodeStart( 'nTimeBegin' ).nodeEnd( 'nTimeEnd' ).brushEvent( events ).nodes( fileBlocks ),
			  xScale = timeline.x(),
			  yScale = timeline.y(),

			svg = d3.select( '#timeline' )
			  .append( 'svg' )
			  .attr( 'width', width )
			  .attr( 'height', height + margin.top + margin.bottom );

			timeline.xAxis();
			timeline.yAxis();

			var chart = svg.append( 'g' )
			  .attr( 'class', 'gantt-chart' )
			  .attr( 'transform', 'translate(' + margin.left + ', ' + margin.top + ')' );

			chart.selectAll( '.bar' )
			  .data( fileBlocks ).enter()
			  .append( 'rect' ).classed( 'bar', true )
			  .attr( 'y', 0 )
			  .attr( 'transform', function( d ) {
			    d.x = xScale( d.nTimeBegin );
			    d.y = yScale( d.name );
			    return 'translate(' + d.x + ',' + d.y + ')';
			  } )
			  .attr( 'height', function( d ) {
			    d.height = yScale.rangeBand();
			    return d.height;
			  } )
			  .attr( 'width', function( d ) {
			    d.width = xScale( d.nTimeEnd ) - xScale( d.nTimeBegin );
			    if ( !d.width ) {
			      d.width = 1;
			    }
			    return d.width;
			  } );

			chart.append( 'rect' ).attr( 'width', width - margin.left - margin.right ).attr( 'height', height ).classed( 'background', true );

			svg.call( timeline.brush ); // indicator on top

			// shorten labels to fit... TODO d3 way
			$( '.tick text' ).each( function( i ) {
			  var label = this.textContent;
			  len = label.length * 7.5;
			  if ( len > margin.left ) {
			    var chop = Math.round( ( len - margin.left ) / 10 );
			    this.textContent = label.substring( 0, ( label.length / 2 - chop / 2 ) ) +
			      '...' + label.substring( ( label.length / 2 + chop / 2 ), label.length );
			  }
			} );
		} );
		</script>

		<!--- write the file content out to script tags for the source file content cache --->
		<cffunction name="prettyName" returntype="String">
			<cfargument name="jrnl" required="true" />
			<cfargument name="fileId" required="true" />
			<cfset var physPath = ExpandPath( "/" ) />
			<cfreturn Replace( jrnl.files[Fix( fileId )].name, physPath, "" ) />
		</cffunction>

		<cfloop array="#files#" index="f" item="fil">
		<cfoutput><script type="application/json" id="source-file-content-#f#">#fil#</script></cfoutput>
		</cfloop>
		<!--- end source file content --->

	</cfif>
		

<cfinclude template="footer.cfm">