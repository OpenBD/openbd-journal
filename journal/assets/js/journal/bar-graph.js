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
 * @version $Id: bar-graph.js 2522 2015-02-19 23:14:55Z wpultz $
 * @author wpultz
 * @class journal.bar-graph
 *
 * note that in order for the bar-height calculation to work properly, the specified container must have a height specified
 */

function BarGraph( _$cont, _opts ) {

	var $cont = _$cont,
		options = _opts || {},
		DEFAULT_COLOR = '#24A7DF';

	// get the width of the container, to calculate the size of each bar against
	var width = $cont.width(),
		height = $cont.height();


	/**
	 * @method setData
	 * @param {map} _dat mapping defining data for each bar, of the format [ { cat: 'data bar name', value: 'data value', href: 'optional, provide address to link bar to' } ]
	 */
	var setData = function( _dat ) {

		var container = d3.select( $cont[ 0 ] );

		// find the largest value, create links
		var largVal = 0,
			links = '';
		for ( var i = 0, len = _dat.length; i < len; i++ ) {
			if ( _dat[ i ].value > largVal ) {
				largVal = _dat[ i ].value;
			}
			links += '<li>';
			if ( _dat[ i ].href ) {
				links += '<a href="' + _dat[ i ].href + '" target="_blank">' + _dat[ i ].cat + '</a>';
			} else {
				links += _dat[ i ].cat;
			}
			links += '</li>';
		}

		container.append( 'ul' ).classed( 'bar-links', true ).html( links );

		// Create bars
		var bars = container.append( 'div' ).classed( 'bars-container', true ).selectAll( 'div' );

		// remove the existing data
		bars.remove();

		// Set left margin & bar height
		var linksWidth = container.selectAll( '.bar-links' ).node().clientWidth + 10,
			barHeight = 20;

		// append new datas
		bars.data( _dat ).enter().append( 'div' )
			.style( 'background-color', function( _dat ) {
				return _dat.color ? _dat.color : DEFAULT_COLOR;
			} )
			.style( 'width', function( _dat ) {
				return ( Math.floor( ( width - linksWidth ) * ( _dat.value / largVal ) ) + 'px' );
			} )
			.style( 'height', barHeight + 'px' )
			.html( function( _dat ) {
				return '<span style="float:right;margin-right:10px;color:#ffffff">' + _dat.value + '</span>'
			} );
	};

	return {
		setData: setData
	};
}