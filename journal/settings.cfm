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

	$Id: settings.cfm 2522 2015-02-19 23:14:55Z wpultz $
--->
<script type="text/javascript">
	$( document ).ready( function() {
		var password = $('#_openbdjournal'),
			passParent = password.parent();

		if ( document.cookie.indexOf( '_openbdjournal' ) == -1 ) {
			$( '#enable' ).show();
			$( '#disable' ).hide();
		} else {
			$( '#enable' ).hide();
			$( '#disable' ).show();
		}
		$( '#journalController #enable' ).on( 'click', function() {
			var uri = $( '#path' ).val();
			var pass = $( '#_openbdjournal' ).val();
			if( $( '#session_capture' ).is( ':checked' ) ) {
				pass += '-1';
			}
			var sep = ( uri.indexOf( '?' ) == -1 ) ? '?' : '&';
			switch ( $( '#method' ).val() ) {
				case 'fjournal':
					return false;
					break;
				case 'ujournal':
					uri = uri + sep + '_openbdjournal=' + pass;
					break;
				case 'cJournal':
					document.cookie = '_openbdjournal=' + pass + '; path=/';
					$( '#enable' ).hide();
					$( '#disable' ).show();
					break;
			}

			window.location.replace( uri );
			return false;
		} );

		$( '#disable' ).on( 'click', function() {
			document.cookie = '_openbdjournal=; path=/ ;expires=Thu, 01 Jan 1970 00:00:01 GMT';
			$( '#enable' ).show();
			$( '#disable' ).hide();
		} );
	} );	
</script>
<div class="controller">
	<form action="" method="" id="journalController" class="pure-form">
		<label for="method">Capture method: 
			<select name="method" id="method">
			<option value="ujournal">URL</option>
			<!--- <option value="fjournal">FORM</option> --->
			<option value="cJournal">COOKIE</option>
			</select>
		</label> 
		<label for="path">Capture URL: <input type="text" name="path" id="path" value="/" /></label>
		<label for="_openbdjournal">Password: <input type="text" name="_openbdjournal" id="_openbdjournal" /></label>
		<label for="session_capture" class="pure-checkbox"><input type="checkbox" name="session_capture" id="session_capture" title="Capture extra session data" /> Capture Session</label>
		<button type="submit" id="enable" class="pure-button pure-button-primary large">Create Journal</button>
		<button type="button" id="disable" class="pure-button button-success">Done</button>
	</form>
</div>