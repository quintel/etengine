//= require <lib/models/game/gas_field>

/**
 * The GasFieldController controls the gasfields of the game. The electricity network
 * consists of a couple of nodes and edges. These are used sometimes as constraint for placing
 * an movieclip on stage. 
 * 
 */
var GasFieldController = Controller.extend({
  
  /**
   * Initialization of the electricity network.
   *
   * @param engine - Isometric game engine
   * @param gridController - The controller that controls the grid.
   *  
   */
  init:function(engine, gridController) {
    this.engine = engine;
    this.gridController = gridController;
    this.gasField = GASFIELD2020; // defined in electricity network controller
    this.addGasFields();
  },
  
  
  /**
   * Add the polygons of the network lines to the 3d engine.
   */
  addGasFields:function() {
    this.engine.polygons.push(this.gasField.getPolygon());      
  },
  
  
  /**
   * Here the electricitynetwork is used as a constraint. Oil plants can only be built if the 
   * electricity network has enough capicity. At this time the constraint is only that only a few grid
   * cells around the lines are available for building a plant.
   */
  getAvailableGridCells:function() {
    var cells = [];
    for(var i = 0; i < this.gasField.points.length; i++) {
      var point = this.gasField.points[i];
      var cell = this.gridController.grid.findNearestCell(point.clone());
      cells.push(cell);
      cells = cells.concat(cell.adjacentCells());
    }
    
    return cells;
  }
});
