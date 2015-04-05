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
 * @version $Id: tree-heat-map.js 2522 2015-02-19 23:14:55Z wpultz $
 * @class journal.tree-heat-map
 */

function TreeHeatMap( _journalFileName, _contSelector, _uState ) {
	var uState = _uState;

	var jrnlFile = _journalFileName,
		contSelector = _contSelector,
		$cont = $( _contSelector ),
		width = $cont.attr( 'width' ),
		height = $cont.attr( 'height' );


	//get a color range of 20 to represent the top level directory
	var colorBorder = d3.scale.category20c();

	//define list of file stat attributes
	var presetFields = 'nBlank,nComments,nSource,nTag,nScript,nOther,nCoverage';

	//define friendly list of attribute names
	var presetFriendly = {
		nSource: 'Source (all)',
		nTag: 'Source (Tag)',
		nScript: 'Source (Script)',
		nComments: 'Lines of Comment',
		nBlank: 'Blank Lines',
		nOther: 'Other (html, etc...)',
		nCoverage: 'Coverage'
	};

	//define what a tooltip looks like
	//display the file name
	//display all the stats, color the active one in gold
	var tip = d3.tip().attr( 'class', 'd3-tip' ).direction( 'se' )
		.html( function( _d ) {
			var tip = '<strong style="text-decoration: underline;"">' + _d.fullPath + '</strong>';
			if ( _d.stats ) {
				for ( var f in presetFriendly ) {
					var tmpVal = _d.stats[ f ];
					if ( f === 'nCoverage' ) {
						tmpVal = Math.round( tmpVal * 1000 ) / 10 + '%';
					}
					if ( uState.MODE == f ) {
						tip += '</br><em style="color:Gold;">' + presetFriendly[ f ] + ': ' + tmpVal + '</em>';
					} else {
						tip += '</br>' + presetFriendly[ f ] + ': ' + tmpVal;
					}
				}
			}
			return tip
		} );

	//initialize the treemap
	var treemap = d3.layout.treemap()
		.size( [ width, height ] )
		.sticky( true )
		.value( function( _d ) {
			return _d.stats.nSource;
		} );

	//get the treemap container in a D3 object
	var div = d3.select( contSelector );

	//tell D3 the AJAX data source to use, and how to render the graph
	d3.json( 'journal/site.cfc?METHOD=getHeatTree&journal=' + encodeURI( jrnlFile ), function( _error, _root ) {
		var node = div.call( tip )
			.datum( _root )
			.selectAll( '.node' )
			.data( treemap.nodes )
			.enter()
			.append( 'svg:rect' )
			.attr( 'class', 'node' )
			.call( position )
			.attr( 'id', function( _d ) {
				return ( typeof _d.file_id == 'number' && _d.file_id != -1 ) ? 'heat_' + _d.file_id : null;
			} )
			.attr( 'stroke', function( _d ) {
				return _d.root ? colorBorder( _d.root ) : null;
			} )
			.attr( 'fill', function( _d ) {
				return ( _d.stats && _d.stats.nCoverage ) ? 'rgb(' + Math.round( ( 1 - _d.stats.nCoverage ) * 255 ) + ',0,' + Math.round( _d.stats.nCoverage * 255 ) + ')' : 'rgb(255,255,255)';
			} )
			.on( 'mouseover', function( _d ) {
				if ( typeof heatMouseOver === 'function' ) {
					heatMouseOver( _d );
				}
				tip.show( _d );
			} )
			.on( 'mouseout', function( _d ) {
				if ( typeof heatMouseOut === 'function' ) {
					heatMouseOut( _d );
				}
				tip.hide( _d );
			} )
			.on( 'click', heatClick );


		//if we are starting on a mode other than nSource, trigger the change
		//Page needs to be loaded in nSource mode and never normalized or it will render strange
		if ( uState.MODE != 'nSource' ) {
			if ( uState.MODE == 'normalize' ) {
				value = function() {
					return 1;
				};
			} else if ( presetFields.indexOf( uState.MODE ) != -1 ) {
				value = function( _d ) {
					return _d.stats[ uState.MODE ];
				};
			}
			node.data( treemap.value( value ).nodes )
				.transition()
				.duration( 500 )
				.call( position );
		}

		//Watch for the mode select box to change
		d3.select( '#mode' ).on( 'change', function change() {
			//set the state mode value
			uState.MODE = this.value;
			//push the state into history
			history.pushState( uState, 'Coverage', '?' + $.param( uState ) );

			//set the function for data,
			if ( uState.MODE == 'normalize' ) {
				//normalize the data to the same value
				value = function() {
					return 1;
				};
			} else if ( presetFields.indexOf( uState.MODE ) != -1 ) {
				//values are based on the state mode value
				value = function( _d ) {
					return _d.stats[ uState.MODE ];
				};
			}

			//update the nodes
			node.data( treemap.value( value ).nodes )
				.transition()
				.duration( 1500 )
				.call( position );
		} );
		$( '#heatmapLoading' ).hide();
	} );


	//function to calculate the posite, and size of a block
	function position() {
		this.attr( 'x', function( _d ) {
				return _d.x + 'px';
			} )
			.attr( 'y', function( _d ) {
				return _d.y + 'px';
			} )
			.attr( 'width', function( _d ) {
				return Math.max( 0, _d.dx - 1 );
			} )
			.attr( 'height', function( _d ) {
				return Math.max( 0, _d.dy - 1 );
			} );
	}


	function heatMouseOver( _d ) {
		var fileId = _d.file_id;
		$( '#file_' + fileId ).addClass( 'd3-text-highlight' );
	}


	function heatMouseOut( _d ) {
		var fileId = _d.file_id;
		$( '#file_' + fileId ).removeClass( 'd3-text-highlight' );
	}


	function heatClick( _d ) {
		if ( _d.file_id != -1 ) {
			uState.FILE = _d.file_id;
			$( '#source2' ).removeClass( 'right-half' );

			window.open( 'fileCoverage.cfm?JOURNAL=' + uState.JOURNAL + '&FILE=' + uState.FILE );
		}
	}

}