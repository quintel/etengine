/**
 * Point.
 * Point is the class that holds a point. A point consists of an x,y,z. 
 * 
 * == Translate
 * Translating a point means moving a point.
 *
 * == Scale
 * Scale a point means multiplying a point by some integer.
 * 
 * == Rotate
 * Rotate a point around z axis.
 *  
 */ 
var Point = Class.extend({
  init:function(x, y, z) {
    this.x = x;
    this.y = y;
    this.z = z || 0;
  },
  translate:function(point) {
    this.copyPositions(PointUtil.translate(this, point));
  },
  scale:function(scale) {
    this.copyPositions(PointUtil.scale(this, scale));
  },
  rotateZ:function(degrees) {
    this.copyPositions(PointUtil.rotateZ(this, degrees));
  },
  copyPositions:function(point) {
    this.x = point.x;
    this.y = point.y;
    this.z = point.z;
  },
  clone:function() {
    var point = new Point();
    point.copyPositions(this);
    return point;
  }
});



var PointUtil = {
  translate:function(point, delta) {
    return new Point(point.x + delta.x, point.y + delta.y, point.z + delta.z);
  },
  scale:function(point, scale) {
    return new Point(point.x * scale.x, point.y * scale.y, point.z * scale.z);
  },
  rotateZ:function(point,degrees) {
    var angle = (degrees /180) * Math.PI;
    var d = Math.sqrt(Math.pow(point.x,2) + Math.pow(point.y,2));
    var alpha = Math.atan2(point.y, point.x) + angle;
    return new Point(Math.cos(alpha) *d, Math.sin(alpha)*d, point.z)
  },
  difference:function(p1, p2) {
    return new Point(p1.x - p2.x, p1.y - p2.y, p1.z - p2.z);
  },
  distance:function(p1, p2) {

    return Math.sqrt(Math.pow(p2.x-p1.x,2) + Math.pow(p2.y-p1.y, 2));
  }
  
}
