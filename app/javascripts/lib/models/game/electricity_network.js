
var ElectricityNetwork = Class.extend({
  init:function() {
    this.nodes = [];
    this.lines = [];
  },
  
  /**
   * Add nodes to this 
   *
   */
  addNode:function(node) {
    this.nodes.push(node);
  },
  
  /**
   * Find a node
   */ 
  findNode:function(point) {
    for(var i = 0; i < this.nodes.length; i++) {
      if(this.nodes[i].getPoint().x == point.x && this.nodes[i].getPoint().y == point.y) {
        return this.nodes[i];
      }
    }
  },
  
  /**
   * Find the node, if it doesn't exist, create it;
   */
  findOrCreateNode:function(point) {
    var node = this.findNode(point);
    if(!node) {
      node = new ElectricityNode(point);
      this.nodes.push(node);
    }
    return node;
  },
  
  /**
   * Add an electricity line.
   */
  addElectricityLine:function(beginPoint, endPoint) {
    var beginNode = this.findOrCreateNode(beginPoint);
    var endNode = this.findOrCreateNode(endPoint);
    this.lines.push(new ElectricityLine(beginNode, endNode));
  },
  
  getPolygons:function(options) {
    var polygons = [];
    for(var i = 0; i < this.lines.length; i++) {
      polygons.push(this.lines[i].getPolygon(options));
    }
    return polygons;
  }
});



var ElectricityNode = Class.extend({
  init:function(point) {
    this.point = point;
  },
  getPoint:function() {
    return this.point;
  }
});


var ElectricityLine = Class.extend({
  init:function(beginNode, endNode) {
    this.beginNode = beginNode;
    this.endNode = endNode;
  },
  getPolygon:function(options) {
    options = options || {};
    attr = options.attr || {'stroke-linejoin':'round', 'stroke':'red', 'stroke-width':2};
    if(this.polygon)
      return this.polygon;
    this.polygon = new Polygon(new Path([this.beginNode.getPoint().clone(), this.endNode.getPoint().clone()]), attr);
    return this.polygon;
  }
});




var Network2020 = new ElectricityNetwork();
var lines = [];


lines.push([new Point(68.51609788147812,-91.70561360904868,0),
new Point(70.88780896199083,-81.16473848157186,0),
new Point(80.37465328404164,-71.15090711046881,0),
new Point(80.90170019082224,-59.55594447024427,0),
new Point(82.74636436455435,-52.177331881010474,0),
new Point(81.95579400438345,-41.10941299715976,0),
new Point(71.41485586877144,-41.10941299715978,0),
new Point(61.664488093330334,-22.135837767701418,0),
new Point(57.448112839085496,-4.216350050990748,0),
new Point(42.954322902618976,-4.743393807364593,0),
new Point(41.10965872888687,11.594962640224546,0),
new Point(28.987579872933047,24.244012793196777,0),
new Point(19.50073555088224,23.716969036822945,0),
new Point(-40.84613527549659,35.31193167704748,0),
new Point(-55.6034486653534,44.27167553540282,0),
new Point(-65.88086334757512,45.325763048150506,0),
new Point(-75.36770766962594,46.906894317272055,0)]);

lines.push([new Point(19.50073555088224,23.716969036822945,0),
new Point(22.39949353817555,43.21758802265513,0),
new Point(37.94737728820327,56.92072568837504,0),
new Point(32.676908220397266,86.96221980168413,0)]);

lines.push([new Point(-21.34539972461434,33.73080040792597,0),
new Point(-24.771204618688238,14.757225178467614,0),
new Point(-31.622814406836056,21.608794011327568,0),
new Point(-45.58955743652197,22.135837767701403,0),
new Point(-51.650596864498894,16.338356447589142,0),
new Point(-58.238683199256435,7.378612589233797,0)]);


lines.push([new Point(-24.50768116529794,15.8113126912153,0),
new Point(-24.50768116529794,15.8113126912153,0),
new Point(-19.237212097491934,2.3558012164417324e-15,0),
new Point(-13.966743029685926,-16.338356447589135,0),
new Point(-19.500735550882236,-23.189925280449096,0),
new Point(-28.197009512762158,-24.244012793196774,0)]);

lines.push([new Point(-13.17617266951502,-13.176093909346081,0),
new Point(-2.3717110805127053,-17.919487716710666,0),
new Point(20.027782457662838,-31.622625382430584,0),
new Point(26.61586879242035,-37.947150458916695,0),
new Point(50.86002650432799,-36.366019189795175,0),
new Point(60.873917733159416,-22.135837767701407,0)]);



for (var k=0; k < lines.length; k++) {
  for (var i=0; i < lines[k].length - 1; i++) {
    Network2020.addElectricityLine(lines[k][i], lines[k][i+1]);
  }
}


/** gas network **/





var GasNetwork2020 = new ElectricityNetwork();
var lines = [];

lines.push([new Point(38.890872965260115, -95.45941546018392),
new Point(35.355339059327385, -28.284271247461906),
new Point(31.819805153394636, -10.606601717798211),
new Point(28.284271247461902, 77.78174593052023)]);



for (var k=0; k < lines.length; k++) {
  for (var i=0; i < lines[k].length - 1; i++) {
    lines[k][i].x = lines[k][i].x + Math.random() * 10 - 5;
    lines[k][i].y = lines[k][i].y + Math.random()* 10 - 5;
    GasNetwork2020.addElectricityLine(lines[k][i], lines[k][i+1]);
  }
}

