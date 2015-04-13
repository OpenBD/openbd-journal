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
	<script src="assets/js/journal/d3.layout.gantt.js"></script>
	</cfif>
</head>
<body>
	<div id="topbar">
		<div class="topbar-contents">

			<a href="/journal/" title="OpenBD Journal - Home"><img src="assets/img/openBD_57px.png"></a>

			<h1><cfif isDefined('title') && title != ''><cfoutput>#title#</cfoutput><cfelse>Journal</cfif></h1>

			<cfif current != 'index.cfm' && current != 'login.cfm'>
			<div class="pure-menu pure-menu-horizontal large"><cfoutput>
				<ul class="pure-menu-list">
					<!--- <li class="pure-menu-item"><a href="index.cfm" class="pure-menu-link">Home</a></li> --->
					<cfif url.journal != "">
					<li class="pure-menu-item"><a href="coverage.cfm?journal=#url.journal#" class="pure-menu-link">Journal: #url.journal#<cfif isDefined('file1name')></cfif></a></li>
					<cfelse>					
					<li class="pure-menu-item"><a href="" class="pure-menu-link">#ReReplace(ReReplaceNocase(current, '([A-z]+).cfm', '\u\1'), '([a-z])([A-Z])', '\1 \2', 'ALL')#</a></li>
					</cfif>
					<cfif isDefined('file1name')>
					<li class="pure-menu-item"><a href="" class="pure-menu-link">File: #file1name#</a></li>
					</cfif>
				</ul>
			</cfoutput></div>

			<cfif url.journal != "">
			<div class="top-buttons"><cfoutput>
				<a href="coverage.cfm?journal=#url.journal#" class="pure-button button-warning<cfif findnocase('coverage', current) gt 0> pure-button-active</cfif>">coverage</a>
				<cfif ( IsSimplevalue(journal) && left( journal, 9 ) != "/compound" ) or ( isStruct(journal) && left( journal.relativeToJournal, 9 ) != "/compound" ) ><a href="code-trace.cfm?journal=#url.journal#" class="pure-button button-secondary<cfif current == 'code-trace.cfm'> pure-button-active</cfif>">performance</a></cfif>
			</cfoutput></div>
			</cfif>

			</cfif>
		</div>
	</div>

	<div id="container">