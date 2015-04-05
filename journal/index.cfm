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

	/**
		* @class journaling.index
		*/
	--->
<cfset title = 'Journal Files'>
<cfset brw = new journal.browser()>
<cfset helper = new journal.helpers()>

<!--- File option, deleting and compounding files --->
<cfif structKeyExists(form, "fileOption") AND structKeyExists(form, "fl")>
	<!--- Check the option chosen --->
	<cfif form.fileOption == "delete">
		<!--- Make sure the list is not empty --->
		<cfif Len(form.fl) GT 0>
			<cfloop list="#form.fl#" index="ind">
				<cfset brw.purgeJournal( getJournalDirectory() & '/' & ind)>
			</cfloop>
			<cfsavecontent variable="message"><cfoutput>
				<span style="color:green;">#ListLen(form.fl)# file<cfif ListLen(form.fl) GT 1>s</cfif> deleted.</span><br>
			</cfoutput></cfsavecontent>
		</cfif>
	<cfelseif form.fileOption == "compound">
		<!--- Make sure the list contains at least two files --->
		<cfif listLen(form.fl) GT 1>
			<cfset cmp = CreateObject("component", "journal.compound")>
			<cfset list = listToArray( listSort(form.fl, "text") )>
			<cfset compStatus = cmp.compoundJournals( _files = form.fl )>
			<cfif compStatus._success>
				<cfsavecontent variable="message"><span style="color:green;">Files compounded!</span></cfsavecontent>
			<cfelse>
				<cfsavecontent variable="message"><span style="color:red;">Compound failed!</span></cfsavecontent>
			</cfif>
		<cfelse>
			<cfsavecontent variable="message"><span style="color:red;">To create a compound file, you need to select a start and end file.</span></cfsavecontent>
		</cfif>
	<cfelse>
		<cfsavecontent variable="message">I've no idea how you managed to get to the else switch, go you!</cfsavecontent>
	</cfif>
</cfif>

<cfinclude template="header.cfm">

	<cfinclude template="settings.cfm">

	<cfif isDefined('message')>
		<p><cfoutput>#message#</cfoutput></p>
	</cfif>

	<cfif (!structKeyExists(URL,"j"))>

	<h3 id="checkReload" style="visible:none;">&nbsp;</h3>

	<cfset browser = brw.queryAllJournals("","",true)>
	<form action="" method="post" class="pure-form ">
		<table id="allJournals" border="0" cellspacing="0" class="pure-table pure-table-bordered pure-table-striped">
			<thead>
				<tr>
					<th><label class="pure-checkbox small"><input type="checkbox" id="checkAll"> all</label></th>
					<th></th>
					<th>Journal</th>
					<th>Starting URI</th>
					<th>Created</th>
					<th>Output</th>
					<th>Size</th>
					<th>Time</th>
					<th><label class="pure-checkbox"><input type="checkbox" id="files-control" checked> Show Coverage Files</label></th>
				</tr>
			</thead>
			<cfif (browser.recordCount > 0)>
			<cfloop query="browser"><cfoutput>
				<cftry>
					<cfset journal = brw.getJournal(browser.directory & '/' & browser.name)>
					<tr>
						<td><input type="checkbox" name="fl" value="#journal.relativeToJournal#"></td>
						<td>
							<a href="coverage.cfm?journal=#journal.relativeToJournal#" class="pure-button small button-warning">coverage</a>
							<cfif !left( journal.relativeToJournal, 9 ) == "/compound"><a href="code-trace.cfm?journal=#journal.relativeToJournal#" class="pure-button small button-secondary">performance</a></cfif>
						</td>
						<td>#journal.relativeToJournal#</td>
						<td>#listFirst(journal.info._uri,"?")#</td>
						<td class="ralign">#DateFormat(journal.timestamp, "dd mmm")#, #TimeFormat(journal.timestamp, "hh:mm:ss tt")#</td>
						<td class="ralign">#journal.info._bytes# bytes</td>
						<td class="ralign">#helper.getNiceSizeFormat( journal.info._fileSize )#</td>
						<td class="ralign">#journal.info._timems# ms</td>
						<td>
							<ul class="coverage_list">
							<cfloop from="1" to="#arrayLen(journal.getFiles())#" index="f">
								<li><a href="fileCoverage.cfm?journal=#journal.relativeToJournal#&file=#f#">#journal.getPrettyFile(f)#</a></li>
							</cfloop>
							</ul>
						</td>
					</tr>
				<cfcatch>
					<tr>
						<td><input type="checkbox" name="fl" value="#browser.name#"></td>
						<td colspan=9>
							An error occurred while reading this journal file.
						</td>
					</tr>
				</cfcatch>
				</cftry>
			</cfoutput></cfloop>
			<cfelse>
				<tr><td colspan="9">There are no journal files. Use the form above to journal pages.</td></tr>
			</cfif>
			<tr>
				<td colspan="9">
					<div style="display:inline-block; vertical-align: middle; margin-right: 1em">
						<label class="pure-radio"><input type="radio" name="fileOption" value="delete"> Delete selected</label>
						<label class="pure-radio"><input type="radio" name="fileOption" value="compound" checked="checked"> Compound selected</label>
					</div>
					<input type="submit" value="Do it" class="pure-button pure-button-primary small">
				</td>
			</tr>
		</table>
	</form>

	</cfif>

	<!--- Normal component version --->
	<script type="text/javascript">
	$( document ).ready( function() {
	  $( "#checkAll" ).on( "click", function() {
	    if ( $( '#checkAll' ).prop( 'checked' ) ) {
	      $( '[name=fl]' ).prop( 'checked', true );
	    }
	    else {
	      $( '[name=fl]' ).prop( 'checked', false );
	    }
	  } );

	  $( "#files-control" ).on( "click", function() {
	    $( ".coverage_list" ).toggleClass( 'hide' );
	  } ).trigger( 'click' );

	  window.latestJournal = '';

	  window.setInterval( function() {
	    $.ajax( {
				url: 'journal/helpers.cfc?METHOD=latestJournalTimestamp',
				type: 'POST',
				dataType: 'HTML',
				success: function( i ) {
					if ( window.latestJournal.length == 0 ) {
			      window.latestJournal = i;
			    }

			    if ( i != window.latestJournal ) {
			      $( '#checkReload' ).html( '<a href="index.cfm" style="color:red;">There are new journal files, reload?</a>' ).show();
			    }
				},
				error: function( a, b, c ) {
					console.log('Something went wrong when trying to look for new journal files');
				}
			} );
	  }, 4000 );
	} );
	</script>
<!--- <cfdbinfo datasource="journaling" type="columns" table="journal" name="bla">
<cfdump var="#bla#">
<cfabort> --->
<cfinclude template="footer.cfm">