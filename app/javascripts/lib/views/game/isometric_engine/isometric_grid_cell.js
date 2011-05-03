/**
 * GridCell is one cell in a grid. 
 *
 */
var GridCell = Class.extend({
  init:function(x, y, grid) {
    this.x = x;
    this.y = y;
    this.width = grid.gridCellWidth;
    this.height = grid.gridCellHeight;
    this.grid = grid;
  },
  
  /**
   * Get the corner points of this grid cell.
   *
   */
  getCornerPoints:function() {
    var halfY = (this.grid.amtCellsY * this.height) / 2;
    var halfX = (this.grid.amtCellsX * this.width) / 2;    
    var points = [ new Point(this.x * this.width - halfX, this.y * this.height - halfY, 0),
                          new Point((this.x + 1) * this.width - halfX, this.y * this.height - halfY),
                          new Point((this.x + 1 ) * this.width - halfX, (this.y+1) * this.height - halfY)];
                          // new Point(this.x * this.width - halfX, (this.y+1) * this.height - halfY)];
    return points;
  },
  
  
  /**
   * Get's the polygon around this grid cell.
   */
  getPolygon:function() {
    if(this.polygon)
      return this.polygon;
    
    var halfY = (this.grid.amtCellsY * this.height) / 2;
    var halfX = (this.grid.amtCellsX * this.width) / 2;    
    var path = new Path([ new Point(this.x * this.width - halfX, this.y * this.height - halfY, 0),
                          new Point((this.x + 1) * this.width - halfX, this.y * this.height - halfY),
                          new Point((this.x + 1 ) * this.width - halfX, (this.y+1) * this.height - halfY),
                          new Point(this.x * this.width - halfX, (this.y+1) * this.height - halfY)]);
    
    this.polygon = new Polygon(path, {fill:'green', opacity:0.2});
    this.polygon.path.rotateZ(this.grid.rotation.z);
    return this.polygon;
  },
  
  
  adjacentCells:function() {
    var cells = [];

    cells.push(this.grid.getCell(this.x, this.y+1));
    cells.push(this.grid.getCell(this.x+1, this.y+1));
    cells.push(this.grid.getCell(this.x+1, this.y));
    cells.push(this.grid.getCell(this.x-1, this.y+1));
    cells.push(this.grid.getCell(this.x, this.y-1));
    cells.push(this.grid.getCell(this.x-1, this.y-1));
    cells.push(this.grid.getCell(this.x-1, this.y));
        
    cells.push(this.grid.getCell(this.x+1, this.y-1));
    cells.push(this.grid.getCell(this.x-1, this.y-1));
    cells.push(this.grid.getCell(this.x+1, this.y-1));
  
    return cells;
  },
  
  /**
   * Get the left corner top of this cell.
   */
  getCornerLeftTop:function() {
    var halfY = (this.grid.amtCellsY * this.height) / 2;
    var halfX = (this.grid.amtCellsX * this.width) / 2;    
    var point = new Point(this.x * this.width - halfX, this.y * this.height - halfY, 0);
    // console.info(this.x * this.width - halfX)
    point.rotateZ(this.grid.rotation.z);
    return point;
  }
  
});