//= require <lib/models/game/electricity_network>

/**
 * The ElectricityNetworkController controls the electricity network of the game. The electricity network
 * consists of a couple of nodes and edges. These are used sometimes as constraint for placing
 * an movieclip on stage. 
 * 
 */
var ElectricityNetworkController = Controller.extend({
  
  /**
   * Initialization of the electricity network.
   *
   * @param engine - Isometric game engine
   * @param gridController - The controller that controls the grid.
   *  
   */
  init:function(engine, gridController, network, options) {
    this.options = options || {};
    this.engine = engine;
    this.gridController = gridController;
    this.electricityNetwork = network; // defined in electricity network controller
    this.addNetworkLines();
    this.visible = true;
  },
  
  
  /**
   * Add the polygons of the network lines to the 3d engine.
   */
  addNetworkLines:function() {
    this.polygons = this.electricityNetwork.getPolygons(); 
    for(var i = 0; i < this.polygons.length; i++) {
      var polygon = this.polygons[i];
      if(this.options.attr)
        polygon.attr = this.options.attr;
      this.engine.polygons.push(polygon);      
    }
  },
  
  hide:function() {
    for(var i = 0; i < this.polygons.length; i++) {
      this.polygons[i].attr.opacity = 0;
    }
    this.engine.render();
    this.visible = false;
  },
  
  
  show:function() {
    for(var i = 0; i < this.polygons.length; i++) {
      this.polygons[i].attr.opacity = 1;
    }
    this.engine.render();
    this.visible = true;
  },
  toggle:function() {
    if(this.visible) {
      this.hide();
    } else {
      this.show();
    }
  },
  
  /**
   * Here the electricitynetwork is used as a constraint. Oil plants can only be built if the 
   * electricity network has enough capicity. At this time the constraint is only that only a few grid
   * cells around the lines are available for building a plant.
   */
  getAvailableGridCells:function() {
    var cells = [];
    for(var i = 0; i < this.electricityNetwork.lines.length; i++) {
      var line = this.electricityNetwork.lines[i];
      var cell = this.gridController.grid.findNearestCell(line.beginNode.getPoint().clone());
      var cell = this.gridController.grid.findNearestCell(line.endNode.getPoint().clone());
      cells.push(cell);
      cells = cells.concat(cell.adjacentCells());
    }
    
    return cells;
  }
});
