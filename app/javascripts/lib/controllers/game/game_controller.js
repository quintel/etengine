
//= require <lib/controllers/main_controller>
//= require <lib/controllers/game/render_controller>
//= require <lib/controllers/game/interface/interface_controller>
//= require <lib/controllers/game/progress_controller>
//= require <lib/controllers/game/electricity_network_controller>
//= require <lib/controllers/game/gas_field_controller>
//= require <lib/controllers/game/map_controller>
//= require <lib/controllers/game/items_controller>
//= require <lib/controllers/game/grid_controller>



/**
 * This is the main entry point for the 3d game. Here all controllers will 
 * be initialized and the isometric engine as well as grid are initialized.
 */
var GameController = Controller.extend({
  
  /**
   * Initialisation of the engine.
   */
  init:function() {
    this.engine = new IsometricEngine('canvas_3d', '100%', '100%', true);
    this.grid = new IsometricGrid(50, 50, 5, 5);
    
    // initialize all controllers
    this.renderController = new RenderController(this.engine);
    this.itemsController = new ItemsController(this.engine)
    this.itemsController.addEventListener("START_DRAGGING", function() {
      this.renderController.block();
    }.bind(this))
    
    this.itemsController.addEventListener("STOP_DRAGGING", function() {
      this.renderController.unblock();
    }.bind(this))
    
    
    this.interfaceController = new InterfaceController(this.engine);
    this.mapController = new MapController(this.engine);
    this.gridController = new GridController(this.engine, this.grid);
    
    this.progressController = new ProgressController(this.engine);
    this.electricityNetworkController = new ElectricityNetworkController(this.engine, this.gridController, Network2020);
    this.gasNetworkController = new ElectricityNetworkController(this.engine, this.gridController, GasNetwork2020, {attr:{'stroke-linejoin':'round', 'stroke':'green', 'stroke-width':3}});
    
    this.gasFieldController = new GasFieldController(this.engine, this.gridController);
  }
});