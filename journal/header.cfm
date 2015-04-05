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
  
	$Id: header.cfm 2522 2015-02-19 23:14:55Z wpultz $
--->
<cfparam name="title" default="" />
<cfparam name="url.journal" default="" />

<cfset current = listlast(cgi.script_name,"/")>
<!doctype html>
<html>
<head>
	<meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<title>OpenBD Journaling</title>
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="stylesheet" href="assets/css/pure-min.css">
	<!--[if lte IE 8]>
	    <link rel="stylesheet" href="assets/css/grid-old-ie.css">
	<![endif]-->

	<!--- index --->	
	<link rel="stylesheet" type="text/css" href="assets/css/journaling.css"/>
	<script type="text/javascript" src="assets/js/vendor/jquery-2.1.3.min.js"></script>
	<script src="assets/js/journal/bar-graph.js"></script>
	<cfif current != 'index.cfm'>
	<script type="text/javascript" src="assets/js/vendor/d3.min.js"></script>
	<script type="text/javascript" src="assets/js/vendor/d3.tip.js"></script>
	</cfif>

	<!--- code trace --->
	<cfif current == 'code-trace.cfm'>
	<link rel="stylesheet" href="assets/css/code-trace.css" />
	<script src="assets/js/vendor/jquery.scrollTo.min.js"></script>
	<!--- code tracer --->
	<script src="assets/js/journal/source-file-content-cache.js"></script>
	<script src="assets/js/journal/source-file-factory.js"></script>
	<script src="assets/js/journal/source-file.js"></script>
	<script src="assets/js/journal/source-file-tracer.js"></script>
	<script src="assets/js/journal/request-context.js"></script>
	<!--- gantt chart for timeline --->
	<script src="assets/js/vendor/d3.layout.gantt.js"></script>
	</cfif>
</head>
<body>
	<div id="topbar">
		<div class="topbar-contents">
			<a href="/journaling/"><img src="assets/img/openBD_57px.png" align="left"></a>
			<h2><cfif isDefined('title') && title != ''><cfoutput>#title#</cfoutput><cfelse>Journaling</cfif></h2>
			<cfif current != 'index.cfm'>
			<div class="breadcrumbs"><cfoutput>
				<a href="index.cfm">Home <span class="muted">&nbsp;&raquo;</span></a>
				<cfif url.journal != "">
					<a href="coverage.cfm?journal=#url.journal#">Journal: #url.journal#<cfif isDefined('file1name')> <span class="muted">&nbsp;&raquo;</span></cfif></a>
				<cfelse>					
					<a href="">#ReReplace(ReReplaceNocase(current, '([A-z]+).cfm', '\u\1'), '([a-z])([A-Z])', '\1 \2', 'ALL')#</a>
				</cfif>
				<cfif isDefined('file1name')>
					<a href="">File: #file1name#</a>
				</cfif>
			</cfoutput></div>
			<cfif url.journal != "">
				<div class="links">
				<cfoutput>
					<a href="coverage.cfm?journal=#url.journal#" class="pure-button button-warning<cfif findnocase('coverage', current) gt 0> pure-button-active</cfif>">coverage</a>
					<cfif ( IsSimplevalue(journal) && left( journal, 9 ) != "/compound" ) or ( isStruct(journal) && left( journal.relativeToJournal, 9 ) != "/compound" ) ><a href="code-trace.cfm?journal=#url.journal#" class="pure-button button-secondary<cfif current == 'code-trace.cfm'> pure-button-active</cfif>">performance</a></cfif>
				</cfoutput>
				</div>
			</cfif>
			</cfif>
		</div>
	</div>

	<div id="container">