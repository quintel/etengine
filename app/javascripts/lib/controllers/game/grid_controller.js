//= require <lib/models/game/electricity_network>

/**
 * The grid controller controls highlighting of the grid.
 */
var GridController = Controller.extend({
  
  /**
   * Initialisation of the grid controller.
   *
   * @param engine - Isometric 3d engine.
   * @param grid - Grid
   */
  init:function(engine, grid) {
    this.engine = engine;
    this.grid = grid;
    this.engine.polygons.push(this.grid.getPolygon());
    this.engine.addEventListener("INITIALIZED", $.proxy(this.initEventListeners, this));
  },
  
  /**
   * Get the grid.
   * @return [Grid] The grid.
   */
  getGrid:function() {
    return this.grid;
  },

  /**
   * Initialize all event listeners. Certain events are dispatched when clicking on
   * a grid cell for example.
   *
   * @return [Grid] The grid.
   */
  initEventListeners:function() {
    $(this.engine.element).bind('mouseover', $.proxy(this.handleMouseOver, this));
    $(this.engine.element).bind('click', $.proxy(this.handleMouseClick, this));

  },
  
  
  /**
   * Retrieves the cell that is clicked on. Translates the point to real coordinates.
   *
   * @param [MouseEvent] A click event for example.
   */
  getGridPointFromGrid:function(e) {
    var point = this.engine.getRealPointForEvent(e);
    var cell = this.grid.findNearestCell(point);
    return cell;
  },
  
  /**
   *  Retrieves the cell that is clicked on. Translates the point to real coordinates.
   * 
   * @todo The same as getGridPointFromGrid, one must be removed.
   * @param [MouseEvent] A click event for example.
   */
  getCellForEvent:function(e) {
    var point = this.engine.getRealPointForEvent(e);
    return this.grid.findNearestCell(point);
  },
  
  /**
   * Mouse click handler.
   * 
   * @param [MouseEvent]
   */
  handleMouseClick:function(e) {
    var cell = this.getCellForEvent(e);
    console.info(cell.getCornerLeftTop().x, cell.getCornerLeftTop().y);
    
    if(cell)
      this.dispatchEvent("CELL_CLICKED", cell); 
  }, 
  
  /**
   * Mouse over handler.
   * 
   * It now highlights the cell on which it is. Think this must be moved to
   * the game controller.
   *
   * @param [MouseEvent]
   */
  handleMouseOver:function(e) {
    var cell = this.getCellForEvent(e);
    if(cell)
      this.dispatchEvent("CELL_OVER", cell);
    
    //this.highlightGridCell(cell);
          
    if(this.selectedCell && cell != this.selectedCell) {
      //this.unhighlightGridCell(this.selectedCell);
    }
    this.selectedCell = cell;
   
  },
  
  /**
   * Highlight the grid cells. That is give them a light border.
   * 
   * @param [Array[GridCell]] The cells to be highlighted.
   */
  highlightGridCells:function(cells) {
    for (var i=0; i < cells.length; i++) {
      this.highlightGridCell(cells[i]);
    };
  },
  
  /**
   * Highlight one grid cell. 
   * 
   * @param [GridCell] The cell to be highlighted.
   */
  highlightGridCell:function(cell) {
    if(cell && cell.getPolygon().rendered == null) 
      this.engine.renderPolygon(cell.getPolygon());
  },
  
  /**
   * Remove the highlight from grid cells. 
   * 
   * @param [Array[GridCell, ..]] The cell to be highlighted.
   */
  unhighlightGridCells:function() {
    for(var i=0; i < this.grid.cells.length; i++) {
      this.unhighlightGridCell(this.grid.cells[i]);
    }
  },

  /**
   * Remove the highlight from one grid cell. 
   * 
   * @param [GridCell] The cell to be unhighlighted.
   */
  unhighlightGridCell:function(cell) {
    if(cell && cell.getPolygon().rendered) {
      cell.getPolygon().rendered.remove();
      cell.getPolygon().rendered = null;
    }
  }
  
  
});
