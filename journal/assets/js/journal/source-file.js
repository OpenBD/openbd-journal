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
 * @version $Id: source-file.js 2522 2015-02-19 23:14:55Z wpultz $
 * @author wpultz
 * @class journal.source-file
 * @param {numeric} _id file id
 * @param {String} _name file name, not including path
 * @param {String} _path full path to file
 * @param {String} _content content of file
 */
function SourceFile( _id, _name, _path, _content ) {

	var id = _id,
		name = _name,
		path = _path,
		$content = $( _content );


	/**
	 * @method getId
	 * @return {numeric}
	 */
	var getId = function() {
		return id;
	};


	/**
	 * @method getName
	 * @return {String}
	 */
	var getName = function() {
		return name;
	};


	/**
	 * @method getPath
	 * @return {String}
	 */
	var getPath = function() {
		return path;
	};


	/**
	 * @method getContent
	 * @returns {jQuery}
	 */
	var getContent = function() {
		return $content;
	};


	/**
	 * highlights the line specified in this file, and scrolls the file to center the line if possible
	 * @method hlLine
	 * @param {numeric} _lineNum line number to highlight in this file
	 */
	var highlightLine = function( _lineNum ) {
		if ( $content ) {
			var $line = $content.find( 'tr[data-linenum="' + _lineNum + '"]' );
			if ( $line.length ) {
				// take care of highlighting
				$content.find( 'tr[data-linenum]' ).removeClass( 'highlight' );
				$line.addClass( 'highlight' );

				// scroll the content to center the line
				$content.find( '.source-file' ).scrollTo( $line, 100, {
					offset: {
						top: $content.height() / -2
					}
				} );
			}
		}
	};


	return {
		getId: getId,
		getName: getName,
		getPath: getPath,
		getContent: getContent,
		highlightLine: highlightLine
	};
}