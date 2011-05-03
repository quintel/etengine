//= require <lib/models/game/electricity_network>

/**
 * The map of the Netherlands is added to the engine here.
 */
var MapController = Controller.extend({
  
  /**
   * The map is initialized and two versions are added. One real one and a
   * shadow version. 
   *
   * @param [IsometricEngine] The isometric game engine.
   */
  init:function(engine) {
    this.map = new MapPolygon();
    this.engine = engine;
    this.addMap({z:0, fill:'#333', stroke:'#333'});
    this.addMap({z:-1, fill:'#eee'});
    
  },
  
  
  
  /**
   * This adds a map of the Netherlands to the engine. 
   *
   * @params [Hash] A hash with options. The options can be one of the following:
   *    
   *    - fill, a color that is used to fill the map.
   *    - stroke, a stroke that is used for the stroke of the map
   * 
   */
  addMap:function(options) {
    options = options || {};
    z = options.z || 0;
    if(!this.countryMap)
      this.countryMap = this.map.getNormalizedPaths({'quality':0.4});

    for(var k = 0; k < this.countryMap.length; k++) {
      var path = this.countryMap[k].clone();
      path.scale(new Point(180,200,2));
      path.translate(new Point(0,0,z));
      this.engine.addPolygon(path, {
            fill: options.fill || "#ccc",
            stroke: options.stroke || "black",
            "stroke-width": 0.5,
            "stroke-linejoin": "round"
      });  
    }
  }
  
});