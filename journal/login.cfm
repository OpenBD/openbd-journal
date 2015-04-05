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
  
	$Id: login.cfm 2522 2015-02-19 23:14:55Z wpultz $
--->

<cfsilent>
<cfscript>
if( StructKeyExists( form, "journalauth" ) && form.journalauth == "openbdjournal" ) {
	SetCookie( name="openbdjournalauth", value="ok", httponly=true );
	location( "index.cfm" );
} else {
	SetCookie( name="openbdjournalauth", expires="NOW" );
}
</cfscript>
</cfsilent>

<cfinclude template="header.cfm" />

	<form method="POST" action="">
		<p>Enter the OpenBD Journaling Password to continue</p>
		<label>Password <input type="password" name="journalauth" /></label>
		<button type="submit">Login</button>
	</form>

<cfinclude template="footer.cfm" />