/** 
 * OpenBD Journaling Tool
 * Copyright (C) 2015
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @version $Id: source-file-content-cache.js 2522 2015-02-19 23:14:55Z wpultz $
 * @author wpultz
 * caches the content of the source files in use during the request being analyzed. we'll pull them out of the DOM once, and keep them here
 *
 * @class journal.source-file-content-cache
 * @param {Array} _fileIds Array of file ids to gather source file markup for
 */
function SourceFileContentCache( _fileIds ) {

	var cache = {};

	/** 
	 * @private
	 * @method init
	 * @param {Array} _ids
	 */
	var init = function( _ids ) {
		for ( var i = 0; i < _ids.length; i++ ) {
			var $content = $( '#source-file-content-' + i );
			var content = $content.length ? $content.html() : '';
			cache[ i ] = content;
			$content.remove();
		}
	};


	/** 
	 * @method getContent
	 * @param {String} _id file id to get content for
	 * @returns {String} content if found, empty string otherwise
	 */
	var getContent = function( _id ) {
		var content = '';
		if ( cache[ _id ] ) {
			content = cache[ _id ];
		} else {
			console.log( 'content not found for file id [' + _id + ']' );
		}
		return content;
	};


	init( _fileIds );


	// expose public functions
	return {
		getContent: getContent
	};
}