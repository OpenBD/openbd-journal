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
  
	$Id: Application.cfc 2522 2015-02-19 23:14:55Z wpultz $
--->
<cfcomponent output="false"><cfscript>
	// Setting up the application
	this.name = 'OpenBD Journaling';
	this.sessionmanagement = true;
	this.clientmanagement = true;

	function onApplicationStart() {
		// Set up database connection and clean up old table, if it exists.
	  if ( !DataSourceIsValid( "journaling" ) ) {
		  ds = {
			  databasename : "Session1",
			  drivername : "org.h2.Driver",
			  hoststring : "jdbc:h2:file:#GetJournalDirectory()#/journaling;MODE=MYSQL;PAGE_SIZE=112000",
			  username : "",
			  password : ""
		  };
		  DataSourceCreate( "journaling", ds );
		}
		queryRun( "journaling", "DROP TABLE journal IF EXISTS" );
	}


	function onRequestStart( String _pageuri ) {
		if( !DataSourceIsValid( "journaling" ) ) {
			onApplicationStart();
		}

		if( !StructKeyExists( cookie, "openbdjournalauth" ) && !_pageuri.endsWith( "login.cfm" ) ) {
			location( "login.cfm" );
		}
	}
</cfscript></cfcomponent>