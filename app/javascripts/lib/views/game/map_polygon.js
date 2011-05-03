//= require <lib/views/game/netherlands>
//= require <lib/views/game/isometric_engine/isometric_engine>

var MapPolygon = View.extend({
  
  init:function() {
    
  },
  
  getRawPoints:function() {
    return Netherlands;
  },
  
  
  getAllPoints:function() {
    var country = this.getRawPoints();
    var p = [];
    for(var province in country) {
      for(var k = 0; k < country[province].length; k++) {
        p = p.concat(country[province][k]);
      }
    }

    return p;
  },
  
  /**
   * Normalize all x and y's so that they are in the range [0,1].
   */ 
  getNormalizedPoints:function(points) {
    var extremesAndRange = this.getExtremesAndRange();
    var extremes = extremesAndRange.extremes;
    var range = extremesAndRange.range;
    
    var h = Math.random();
    var path = new Path();
    for(var i = 0; i < points.length; i++) {
      
      path.points.push(new Point((points[i][0] - extremes.x.min) / range.x -0.5, (points[i][1] - extremes.y.min) / range.y -0.5, 0));
    }
      
    return path;
  },
  
  getExtremesAndRange:function() {
    if(this.extremes)
      return {extremes:this.extremes, range:this.range};
      
    var points = this.getAllPoints();
    normalized_points = [];
    this.extremes = {x: {min:-1, max:-1}, y: {min:-1, max:-1} };
    for(var i = 0; i < points.length; i++) {
      if(points[i][0] < this.extremes.x.min || this.extremes.x.min == -1)
        this.extremes.x.min = points[i][0];

      if(points[i][0] > this.extremes.x.max || this.extremes.x.max == -1)
        this.extremes.x.max = points[i][0];

      if(points[i][1] < this.extremes.y.min || this.extremes.y.min == -1)
        this.extremes.y.min = points[i][1];

      if(points[i][1] > this.extremes.y.max || this.extremes.y.max == -1)
        this.extremes.y.max = points[i][1];
    }
    
    this.range = {x: this.extremes.x.max - this.extremes.x.min, y: this.extremes.y.max - this.extremes.y.min};
    return {extremes:this.extremes, range:this.range};
  },
  
  getNormalizedPaths:function(options) {
    options = options || {};
    var paths = this.getRawPoints();
    var out = [];
  
    for(var provence in paths) {
      for(var k = 0; k < paths[provence].length; k++) {
        var path = paths[provence][k];
        out.push(this.getNormalizedPoints(path));
      }
    }
    if(options.quality)
      out = this.compressPaths(out, options.quality);
    
    return out;
  },
  
  compressPaths:function(paths, level) {
    out = [];
    for(var i = 0; i < paths.length;i++) {
      var newPath = new Path();      
      newPath.points.push(paths[i].points[0]);
      for(var k = 1; k <paths[i].points.length-1;k++) {
        if(Math.random() > (1-level))
          newPath.points.push(paths[i].points[k]);
      }
      newPath.points.push(paths[i].points[paths[i].points.length -1]);
      out.push(newPath);
    }
    return out;
  }
  
  
  
})