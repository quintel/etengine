//= require <lib/views/game/isometric_engine/isometric_grid_cell>

/**
 * Isometric grid represents a grid of (amtCellsX x amtCellsY) with cells that are
 * (gridCellWidth x gridCellHeight) in real coordinates.
 * 
 * When having a point, the cell that belongs to it can be found by doing: 
 *
 * grid.findNearestCell(new Point(1,2,3))
 *    => <Cell x:1,y:5>
 * 
 * The grid keeps track of a double array. 
 * 
 */ 
var IsometricGrid = Class.extend({
  
  /**
   * Isometric grid.
   */
  init:function(amtCellsX, amtCellsY, gridCellWidth, gridCellHeight, isoMetric) {
    this.amtCellsX = amtCellsX;
    this.amtCellsY = amtCellsY;
    this.gridCellHeight = gridCellHeight;
    this.gridCellWidth = gridCellWidth;
    this.initCells();
    this.rotation = new Point(0, 0, 45);
  },
  
  /**
   * Init all cells in the grid.
   */
  initCells:function() {
    this.cellMatrix = [];
    this.cells = [];
    for(var x = 0; x < this.amtCellsX; x++) {
      this.cellMatrix[x] = [];
      for(var y = 0; y < this.amtCellsY; y++) {
        this.cells[y*this.amtCellsX + x] = this.cellMatrix[x][y] = new GridCell(x,y,this);
      }
    }
  },
  
  /**
   * Get cell in the grid. Efficient to use this when having 
   */
  getCell:function(x, y) {
    return this.cellMatrix[x][y];
  },
  
  /**
   * Get all cells in the grid.
   */
  getCells:function() {
    return this.cells;
  },
  
  /**
   * Find the containing cell. The cell that holds this point.
   */
  findNearestCell:function(point) {
    point.rotateZ(-this.rotation.z);
    var x = Math.floor((point.x) / this.gridCellWidth) + (this.amtCellsX / 2);
    var y = Math.floor((point.y) / this.gridCellHeight) + (this.amtCellsY / 2);
    if(this.cellMatrix[x])
      return this.cellMatrix[x][y];
    return null;
  },
  
  
  
  
  /**
   * Get a polygon that we can use to display this grid.
   */
  getPolygon:function() {
    if(this.polygon)
      return this.polygon;
    var path = [];
    for(var i = 0; i < this.cells.length; i++) {
      path = path.concat(this.cells[i].getCornerPoints());
    }
    var p = new Path(path);
    
    this.polygon = new Polygon(p, {stroke:'#999', opacity:0.2});
    this.polygon.path.rotateZ(this.rotation.z);
    
    return this.polygon;
  }
  
});


