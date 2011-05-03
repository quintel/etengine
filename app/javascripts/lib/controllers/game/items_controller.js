//= require <lib/models/game/placed_category_item>

/**
 * The items are controlled here.
 */
var ItemsController = Controller.extend({
  /**
   * Initialisation of the grid controller.
   *
   * @param engine - Isometric 3d engine.
   * @param grid - Grid
   */
  init:function(engine) {
    this.engine = engine;
    this.placedCatItems = [];
  },
  
  /**
   * This is decides which controller is used for a categoryItem
   */
  getConstraintController:function(categoryItem) {
    if(categoryItem.getConstraintedBy() == CategoryItemConstraint.GAS_FIELD) {
      return ETM.gameController.gasFieldController;
    } else if(categoryItem.getConstraintedBy() == CategoryItemConstraint.GAS_NETWORK) {
      return ETM.gameController.gasNetworkController;
    } else if(categoryItem.getConstraintedBy() == CategoryItemConstraint.ELECTRICITY_NETWORK) {
      return ETM.gameController.electricityNetworkController;
    } else {
      return;
    }
  },
  
  /**
   * Get available grid cells.
   *
   * @param engine - Isometric 3d engine.
   * @param grid - Grid
   */
  getAvailableGridCells:function(categoryItem) {
    var constraintsController = this.getConstraintController(categoryItem);
    var cells = [];
    if(constraintsController) {
      cells = constraintsController.getAvailableGridCells();
    } else {
      cells = ETM.gameController.grid.cells;
    }
    
    // check if it's not on another item
    for(var i = 0; i < this.placedCatItems.length; i++) {
      var p = this.placedCatItems[i].getMC().gridPoint;
      for(var k = 0; k < cells.length; k++) {
        if(cells[k].x == p.x && cells[k].y == p.y)
          cells.splice(k, 1);
      }
    }
    return cells;
  },
  
  /**
   * Is this a valid cell?
   * @param cell The cell we're checking.
   */
  isValidCell:function(cell) {
    
    return this.currentAvailableCells.indexOf(cell) != -1;
  },
  
  
  /**
   * Called when a category item is clicked.
   * @param categoryItemElement The category item element.
   */
  handleCatItemElementClicked:function(categoryItemElement) {
    var catItem = categoryItemElement.categoryItem;
    var mc = ETM.gameController.renderController.addMovieClip(catItem.createMovieClip());
    this.startDragging( catItem, mc);
    ETM.gameController.renderController.engine.element.bind('mouseup', $.proxy(this.handleCategoryItemElementMouseUp, this));
    
  },
  
  
  /**
    * Let the dragging begin.
    * @param catItem Category item.
    * @param mc Movieclip belonging to the category item.
    */
  startDragging:function(catItem, mc) {
    this.dispatchEvent("START_DRAGGING");
    this.draggingCategoryItem = catItem;
    this.draggingMC = mc;
    this.currentAvailableCells = this.getAvailableGridCells(catItem);
    var placedCatItem = this.findPlacedCatItem(this.draggingMC);
    if(placedCatItem) {
      var p = placedCatItem.getMC().gridPoint;
      var cell = ETM.gameController.gridController.getGrid().getCell(p.x, p.y);
      this.currentAvailableCells.push(cell); 
    }
    
    ETM.gameController.gridController.highlightGridCells(this.currentAvailableCells);
    this.draggingListener = $.proxy(this.handleDragCategoryItemElement, this);
    ETM.gameController.gridController.addEventListener("CELL_OVER", this.draggingListener);
    
  },
  
  /**
   * Called when a category item is dragged.
   */
  handleDragCategoryItemElement:function(cell) {
     // var cell = ETM.gameController.gridController.getGridPointFromGrid(e);
     
     if(cell) {
        this.draggingMC.gridPoint.x = cell.x;
        this.draggingMC.gridPoint.y = cell.y;
        ETM.gameController.renderController.engine.renderMovieClips();  
        this.draggingMC.image.css('opacity', 0.2);
     }
     
     if(this.currentAvailableCells.indexOf(cell) != -1) {
        this.draggingMC.image.css('opacity', 1);
     }
  },
  
  /**
   * Called when a category item is clicked and thereafter the mouse is released.
   */
  handleCategoryItemElementMouseUp:function(e) {
    console.info("MOUSE UPD");
    var cell = ETM.gameController.gridController.getGridPointFromGrid(e);
    if(this.currentAvailableCells.indexOf(cell) != -1) {
      this.addItem(this.draggingCategoryItem, this.draggingMC)
    } else {
      ETM.gameController.engine.removeMovieClip(this.draggingMC);
    }
    ETM.gameController.engine.renderMovieClips();
    
    ETM.gameController.gridController.unhighlightGridCells(this.currentAvailableCells)  
    ETM.gameController.gridController.removeEventListener("CELL_OVER", this.draggingListener);
    
    //ETM.gameController.renderController.engine.element.unbind('mouseover', $.proxy(this.handleDragCategoryItemElement, this));
    ETM.gameController.renderController.engine.element.unbind('mouseup', $.proxy(this.handleCategoryItemElementMouseUp, this));
    this.dispatchEvent("STOP_DRAGGING");
  },
  handleMCClicked:function(mc, catItem, e) {
    console.info("START DRAGGING");
    this.startDragging( catItem, mc);
    ETM.gameController.renderController.engine.element.bind('mouseup', $.proxy(this.handleMCUp, this));
  },
  findPlacedCatItem:function(mc) {
    for(var i = 0; i < this.placedCatItems.length; i++) {
      if(this.placedCatItems[i].getMC() == mc)
        return this.placedCatItems[i];
    }
  },
  
  handleMCUp:function(e) {
    var cell = ETM.gameController.gridController.getGridPointFromGrid(e);
    if(!this.isValidCell(cell)) {
      console.info("No ");
      console.info(this.findPlacedCatItem(this.draggingMC));
      this.removeItem(this.findPlacedCatItem(this.draggingMC));
    }
      
    ETM.gameController.gridController.unhighlightGridCells(this.currentAvailableCells)  
    ETM.gameController.gridController.removeEventListener("CELL_OVER", this.draggingListener);
    ETM.gameController.renderController.engine.element.unbind('mouseup', $.proxy(this.handleMCUp, this));
    this.dispatchEvent("STOP_DRAGGING");
  },
  
  removeItem:function(placedCategoryItem) {
    console.info("Removing itme");
    console.info(placedCategoryItem);
    ETM.gameController.engine.removeMovieClip(placedCategoryItem.getMC());
    placedCategoryItem.remove();
    this.placedCatItems.splice(this.placedCatItems.indexOf(this.draggingCategoryItem, 1))
  },
  
  addItem:function(draggingCategoryItem, mc) {
    mc.addEventListener("ADDED_TO_STAGE", function(itemsController, draggingCategoryItem) {
        return function(mc) {
          mc.image.bind('mousedown', function(e) {
            itemsController.handleMCClicked(mc, draggingCategoryItem);  
            e.preventDefault();
          });
        }
    }(this, draggingCategoryItem));
    mc.dispatchEvent("ADDED_TO_STAGE", mc);
    
    var pCItem = new PlacedCategoryItem(draggingCategoryItem,mc);
    pCItem.addedToStage();
    this.placedCatItems.push(pCItem);
    
  }
  
});
