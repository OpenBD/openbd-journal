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
 * @version $Id: tree-map.js 2522 2015-02-19 23:14:55Z wpultz $
 * @class journal.tree-map
 */

function TreeMap( _journalFileName, _contSelector ) {

	var jrnlFile = _journalFileName,
		contSelector = _contSelector,
		$cont = $( _contSelector ),
		treeWidth = $cont.attr( 'width' ),
		treeHeight = $cont.attr( 'height' );

	// define friendly list of attribute names
	// same lookup as what's in the tree-heat-map. get it out of both if possible?
	var presetFriendly = {
		nSource: 'Source (all)',
		nTag: 'Source (Tag)',
		nScript: 'Source (Script)',
		nComments: 'Lines of Comment',
		nBlank: 'Blank Lines',
		nOther: 'Other (html, etc...)',
		nCoverage: 'Coverage'
	};


	// TODO - fix magic numbers
	var force = d3.layout2.force()
		.on( 'tick', tick )
		.charge( function( _d ) {
			return _d._children ? -5 : -40;
		} )
		.linkDistance( function( _d ) {
			if ( _d.target._children ) {
				return 40;
			} else if ( _d.target.children && _d.target.children.length != 0 ) {
				return 40;
			} else {
				return 20;
			}
		} )
		.size( [ treeWidth, treeHeight ] );

	var vis = d3.select( contSelector );

	// TODO - fix magic numbers
	d3.json( 'journal/site.cfc?METHOD=getHeatTree&journal=' + encodeURI( jrnlFile ), function( _json ) {
		root = _json;
		root.fixed = true;
		root.x = treeWidth / 2;
		root.y = treeHeight / 2 - 80;
		update();
	} );

	var treeTip = d3.tip().attr( 'class', 'd3-tip' ).direction( 'se' )
		.html( function( _d ) {
			if ( !_d.hasOwnProperty( 'fullPath' ) ) {
				var tip = '<strong ">Directory: ' + _d.name + '</strong>';
			} else {
				var tip = '<strong style="text-decoration: underline;">' + _d.fullPath + '</strong>';
				if ( _d.stats ) {
					for ( var f in presetFriendly ) {
						var tmpVal = _d.stats[ f ];
						if ( f === 'nCoverage' ) {
							tmpVal = Math.round( tmpVal * 1000 ) / 10 + '%';
						}
						tip += '</br>' + presetFriendly[ f ] + ': ' + tmpVal;
					}
				}
			}
			return tip;

		} );

	function update() {
		var nodes = flatten( root ),
			links = d3.layout2.tree().links( nodes );

		// Restart the force layout.
		force.nodes( nodes ).links( links ).start();

		// Update the links…
		link = vis.selectAll( 'line.directory-file-link' )
			.data( links, function( _d ) {
				return _d.target.id;
			} );

		// Enter any new links.
		link.enter().insert( 'svg:line', '.node' )
			.attr( 'class', 'directory-file-link' )
			.attr( 'x1', function( _d ) {
				return _d.source.x;
			} )
			.attr( 'y1', function( _d ) {
				return _d.source.y;
			} )
			.attr( 'x2', function( _d ) {
				return _d.target.x;
			} )
			.attr( 'y2', function( _d ) {
				return _d.target.y;
			} );

		// Exit any old links.
		link.exit().remove();

		// Update the nodes…

		// TODO - fix magic numbers
		node = vis.call( treeTip ).selectAll( 'circle.node' )
			.data( nodes, function( _d ) {
				return _d.id;
			} )
			.style( 'fill', function( _d ) {
				if ( _d._children ) {
					return 'rgb(255,255,255)';
				} else if ( _d.children && _d.children.length != 0 ) {
					return 'rgb(128,128,128)';
				} else {
					return ( _d.stats && _d.stats.nCoverage ) ? 'rgb(' + Math.round( ( 1 - _d.stats.nCoverage ) * 255 ) + ',0,' + Math.round( _d.stats.nCoverage * 255 ) + ')' : 'rgb(255,255,255)';;
				}
			} );

		node.transition()
			.attr( 'r', function( _d ) {
				if ( typeof _d._children == 'undefined' || _d._children == null || _d._children.length == 0 ) {
					return 4.5;
				} else {
					return 10;
				}
			} );

		// Enter any new nodes.
		// TODO - fix magic numbers
		node.enter().append( 'svg:circle' )
			.attr( 'class', 'node' )
			.attr( 'cx', function( _d ) {
				return _d.x;
			} )
			.attr( 'cy', function( _d ) {
				return _d.y;
			} )
			.attr( 'r', function( _d ) {
				return 4.5;
			} )
			.style( 'fill', function( _d ) {
				if ( _d._children ) {
					return '#24A7DF';
				} else if ( _d.children && _d.children.length != 0 ) {
					return '#24A7DF';
				} else {
					return ( _d.stats && _d.stats.nCoverage ) ? 'rgb(' + Math.round( ( 1 - _d.stats.nCoverage ) * 255 ) + ',0,' + Math.round( _d.stats.nCoverage * 255 ) + ')' : 'rgb(255,255,255)';
				}
			} )
			.on( 'mouseover', function( _d ) {
				treeTip.show( _d );
				var fileId = _d.file_id;
				$( '#file_' + fileId ).addClass( 'd3-text-highlight' );
			} )
			.on( 'mouseout', function( _d ) {
				treeTip.hide( _d );
				var fileId = _d.file_id;
				$( '#file_' + fileId ).removeClass( 'd3-text-highlight' );
			} );

		// Exit any old nodes.
		node.exit().remove();
	}

	function tick() {
		link.attr( 'x1', function( _d ) {
				return _d.source.x;
			} )
			.attr( 'y1', function( _d ) {
				return _d.source.y;
			} )
			.attr( 'x2', function( _d ) {
				return _d.target.x;
			} )
			.attr( 'y2', function( _d ) {
				return _d.target.y;
			} );

		node.attr( 'cx', function( _d ) {
				return _d.x;
			} )
			.attr( 'cy', function( _d ) {
				return _d.y;
			} );
	}

	// TODO - fix magic hex values
	// Color leaf nodes orange, and packages white or blue.
	function color( _d ) {
		return _d._children ? '#3182bd' : _d.children ? '#c6dbef' : '#fd8d3c';
	}

	// Toggle children on click.
	function click( _d ) {
		if ( _d.children ) {
			_d._children = _d.children;
			_d.children = null;
		} else {
			_d.children = _d._children;
			_d._children = null;
		}
		update();
	}

	// Returns a list of all nodes under the root.
	function flatten( _root ) {
		var nodes = [],
			i = 0;

		function recurse( _node ) {
			if ( _node.children ) _node.size = _node.children.reduce( function( _p, _v ) {
				return _p + recurse( _v );
			}, 0 );
			if ( !_node.id ) _node.id = ++i;
			nodes.push( _node );
			return _node.size;
		}

		_root.size = recurse( _root );
		return nodes;
	}
}