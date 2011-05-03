/**
 * A polygon consists of a path and a attributes hash. This attributes
 * hash is a Raphael hash with attributes. Check Raphael documentation on how 
 * to make the polygon have a fill for example.
 */
var Polygon = Class.extend({
  init:function(path, attr) {
    this.path = path;
    this.attr = attr;
    this.rendered = null;
  }
});
