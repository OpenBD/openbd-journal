/**********************************************************
 * Author: @CaitlinMWeb
 * Special thanks to https://github.com/dk8996/Gantt-Chart,
 * http://bl.ocks.org/mbostock/6452972
 *********************************************************/
d3.layout.gantt = function() {
  // defaults
  var width = document.body.clientWidth,
    height = document.body.clientHeight,
    nodes = [],
    labels = [],
    nodeStart = 'startDate',
    nodeEnd = 'endDate',
    labelY = 'name',
    current = 0,
    events = {
      'brushstart': null,
      'brush': null,
      'brushend': null
    },
    margin = {
      top: 10,
      right: 50,
      bottom: 10,
      left: 50
    };
  // functions
  var x = d3.scale.linear(),
    xAxis = d3.svg.axis().scale( x ).orient( 'bottom' ).tickSize( 0 ).tickPadding( 0 ),
    y = d3.scale.ordinal(),
    yAxis = d3.svg.axis().scale( y ).orient( 'right' ).tickSize( 0 ).tickPadding( 0 ),

    brushed = function( value ) {
      if ( value === undefined ) {
        xVal = d3.mouse( this )[ 0 ];
        value = Math.round( x.invert( xVal - margin.left ) );
      }
      else {
        xVal = x( value ) + margin.left;
      }
      current = value;

      var indicator = d3.selectAll( '.extent' ).attr( 'width', 1 ).attr( 'x', xVal );
      if ( !indicator.attr( 'height' ) ) {
        indicator.attr( 'height', height - margin.top - margin.bottom );
      }

      if ( events.brush ) {
        events.brush( current );
      }
    };

  function gantt( d, i ) {
    var node,
      min = 9999,
      max = 0;
    for ( var n = 0; n < nodes.length; n++ ) {
      node = nodes[ n ];
      labels.push( node[ labelY ] );
      min = Math.min( min, node[ nodeStart ] );
      max = Math.max( max, node[ nodeEnd ] );
    }
    x.rangeRound( [ 0, width - margin.left - margin.right ] ).domain( [ min, max ] );
    y.rangeRoundBands( [ 0, height - margin.top - margin.bottom ], 0 ).domain( labels );
    gantt.brush.x( x );
    return gantt;
  }

  gantt.brush = d3.svg.brush()
    .on( 'brush', brushed )
    .on( 'brushend', function() {
      if ( events.brushend ) {
        events.brushend( current );
      }
    } );

  // required
  gantt.nodes = function( value ) {
    if ( !arguments.length ) {
      return nodes;
    }
    nodes = value;
    gantt();
    return gantt;
  };
  // options
  gantt.width = function( value ) {
    if ( !arguments.length ) {
      return width;
    }
    width = value;
    return gantt;
  };
  gantt.height = function( value ) {
    if ( !arguments.length ) {
      return height;
    }
    height = value;
    return gantt;
  };
  gantt.margin = function( value ) {
    if ( !arguments.length ) {
      return margin;
    }
    margin = value;
    return gantt;
  };
  gantt.y = function( value ) {
    if ( !arguments.length ) {
      return y;
    }
    y = value;
    return gantt;
  };
  gantt.x = function( value ) {
    if ( !arguments.length ) {
      return x;
    }
    x = value;
    return gantt;
  };
  gantt.xAxis = function( value ) {
    if ( !arguments.length ) {
      var axis = d3.select( 'svg' ).append( 'g' ).attr( 'class', 'x axis' )
        .attr( 'transform', 'translate(' + margin.left + ',' + ( height + margin.top ) + ')' ).call( xAxis );
      axis.selectAll( 'line' ).attr( 'y1', -4 ).attr( 'y2', -height + margin.top );
    }
    xAxis = value;
    return gantt;
  };
  gantt.yAxis = function( value ) {
    if ( !arguments.length ) {
      var axis = d3.select( 'svg' ).append( 'g' ).attr( 'class', 'y axis' ).attr( 'transform', 'translate(5,0)' ).call( yAxis );
      axis.selectAll( 'line' ).attr( 'x1', 0 ).attr( 'y1', y.rangeBand() / 2 ).attr( 'x2', width ).attr( 'y2', y.rangeBand() / 2 );
    }
    yAxis = value;
    return gantt;
  };
  gantt.nodeStart = function( value ) {
    if ( !arguments.length ) {
      return nodeStart;
    }
    nodeStart = value;
    return gantt;
  };
  gantt.nodeEnd = function( value ) {
    if ( !arguments.length ) {
      return nodeEnd;
    }
    nodeEnd = value;
    return gantt;
  };
  gantt.labelY = function( value ) {
    if ( !arguments.length ) {
      return labelY;
    }
    labelY = value;
    return gantt;
  };
  gantt.brushEvent = function( value, stage ) {
    if ( !arguments.length ) {
      return events;
    }
    if ( stage ) {
      events[ stage ] = value;
    }
    else {
      if ( value.constructor === Object ) {
        events = value;
      }
    }
    return gantt;
  };
  gantt.goTo = function( value ) {
    brushed( value );
  };

  return gantt;
};
