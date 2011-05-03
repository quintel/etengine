/**
 * A path consists of some points. You can translate, rotate and scale a path.
 *
 */
var Path = Class.extend({
  init:function(points) {
    this.points = points || [];
  },
  translate:function(point) {
    for(var i = 0; i < this.points.length; i++ ) 
      this.points[i].translate(point);
  },
  scale:function(scale) {
    for(var i = 0; i < this.points.length; i++ ) 
      this.points[i].scale(scale);
  },
  rotateZ:function(degrees) {
    for(var i = 0; i < this.points.length; i++ ) 
      this.points[i].rotateZ(degrees);
  },
  clone:function() {
    var path = new Path();
    for(var i = 0; i < this.points.length; i++ ) 
      path.points.push(this.points[i].clone());
    return path;
  }
  
});