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

	$Id: bar.cfm 2522 2015-02-19 23:14:55Z wpultz $
--->
<cfsilent>

	<cftry>
		<cfset parser = new journal.parser( GetJournalDirectory() & url.journal )>
		<cfset helper = new journal.helpers()>

		<cfset _file_path_to_webroot = expandPath("/")>

		<cfset fileList = [""]>
		<cfset valList = []>

		<cfloop from="1" to="#ArrayLen(parser.files)#" index="i">
			<cfset temp = parser.getHitLineCount( _journal = GetJournalDirectory() & url.journal, _fileId = i )>
			<cfset shorterName = helper.getWebRootRelativeJournalFilePath( parser.files[i].name, _file_path_to_webroot )>
			<cfset ts = { cat: shorterName, value: temp, href: "fileCoverage.cfm?JOURNAL=#url.journal#&FILE=#i#&MODE=nSource" }>
			<cfset arrayAppend(valList, ts)>
		</cfloop>

		<cfif arrayLen(valList) GT 4>
			<cfset barTotalHeight = ( arrayLen( valList ) * 25 + 5 )>
		<cfelse>
			<cfset barTotalHeight = ( arrayLen( valList ) * 40 + 5 )>
		</cfif>
	<cfcatch>
	</cfcatch>
	</cftry>

	
</cfsilent>


<cfinclude template="header.cfm">

<cfif IsDefined( "valList" )>
	<p>
		Graphical representation of the total number of lines hit per file.
	</p>
	<div id="horizontalBarGraph" style="height:<cfoutput>#barTotalHeight#</cfoutput>px"></div>

	<script>
		$( function() {
			var bargraph = new BarGraph( $('#horizontalBarGraph' ) );
			bargraph.setData( <cfoutput>#SerializeJson( valList )#</cfoutput> );
		} ) ();
	</script>

<cfelse>
	
	<p>An error was encountered while reading this journal file. Please return to the <a href="index.cfm">Journaling Home Page</a> and select another journal.</p>

</cfif>

<cfinclude template="footer.cfm">