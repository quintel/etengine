var GasField = Class.extend({
  
  init:function(midPoint, r) {
    this.r = r;
    this.midPoint = midPoint;
    this.calculatePoints();
  },
  calculatePoints:function() {
    var points = [];

    var amtSamples = 30;
    var sampleSize = (2*Math.PI) / amtSamples;

    var radius = this.r;

    var position = 0;
    for (var i=0; i < amtSamples; i++) {
      x = (radius * Math.cos(position)) + this.midPoint.x;
      y = (radius * Math.sin(position)) + this.midPoint.y;

      radius += (this.r * 0.25) * (Math.random() - 0.5);
      points.push(new Point(x, y));
      position += sampleSize;
    };

    this.points = points;
  },
  
  getPolygon:function() {
    return new Polygon(new Path(this.points), {'stroke-linejoin':'round', 'stroke':'white', 'stroke-width':1, 'fill':'#999', 'opacity':0.8});
  }
  
});



GASFIELD2020 = new GasField(new Point(40,-100), 10);