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
 * returns a source file object for the given file id, including the content for from that file
 *
 * @version $Id: source-file-factory.js 2522 2015-02-19 23:14:55Z wpultz $
 * @author wpultz
 * @class journal.source-file-factory
 * param {Object} _contentCache
 */
function SourceFileFactory( _contentCache ) {

	var contentCache = _contentCache;


	/**
	 * @method getSourceFile
	 * @param {numeric} _id file id
	 * @param {String} _name file name, not including any part of the file path
	 * @param {String} _path full path to the file
	 * @return {Object}
	 */
	var getSourceFile = function( _id, _name, _path ) {
		return new SourceFile( _id, _name, _path, contentCache.getContent( _id ) );
	};


	// expose public function
	return {
		getSourceFile: getSourceFile
	};
}