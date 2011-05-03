
/**
 * Movieclip is an isometric movieclip, that is, a simple image that is scaled when
 * and placed in view coordinates when it's rendered.
 *
 * == Image scale
 * The image scale let's you set at which resolution an image must be displayed. Setting the 
 * image scale, very high, let's you zoom in without having a very blurry picture, requires a
 * larger picture however.
 *
 */
var MovieClip = EventDispatcher.extend({
  init:function(url, gridPoint, grid) {
    this.grid = ETM.gameController.gridController.getGrid();
    this.url = url || '/images/isometric/windmill.png';
    this.gridPoint = gridPoint || new Point(parseInt(Math.random()*50),parseInt(Math.random()*50));
    this.element = $('<div>');
    this.image = $('<img src="'+ this.url + '" />')
    this.element.append(this.image);
    this.addedToStage = false;
  },
  setViewPoint:function(point) {
    
    
  },

  
  getPoint:function() {
    // if(this.point)
      // return this.point;
    var cell = this.grid.getCell(this.gridPoint.x, this.gridPoint.y);
    this.point = cell.getCornerLeftTop();
    return this.point;
    
  },
  
  getImageWidth:function() {
    return 200 / this.getImageScale();
  },
  getImageHeight:function() {
    return 300 / this.getImageScale();
  },
  getTopOffset:function() {
    return 190 / this.getImageScale();
  },
  getImageScale:function() {
    return 25;
  }
  
  
  
});
