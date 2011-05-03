//= require <lib/views/game/map_polygon>
//= require <lib/views/game/isometric_engine/isometric_engine>
//= require <lib/models/game/electricity_network>

/**
 * The render controller controls the rendering of the engine.
 */
var RenderController = Controller.extend({
  init:function(engine) {
    this.engine = engine;

    this.engine.addEventListener("INITIALIZED", $.proxy(function() {
      $(this.engine.element).bind('mousedown', $.proxy(this.handleStartDrag, this));
    }, this));
    
  },
  
  /**
   * Get the engine
   */
  getEngine:function() {
    return this.engine;
  },
  
  /**
   * Add a movieclip to the engine.
   */
  addMovieClip:function(isoMetricM) {
    return this.engine.addMovieClip(isoMetricM);
  },

  /**
   * Zoom in,
   */
  zoomIn:function() {
    this.zoom(2);
  },
  
  /**
   * Zoom out,
   */
  zoomOut:function() {
    this.zoom(0.5);
  },
  
  setZoomLevel:function(l) {
    l = l * 10;
    this.engine.scaling = new Point(l,l,l);

    this.render();
  },
  
  
  move:function(point) {
    this.engine.translation.translate(point);
    this.render();
  },
  
  /**
   * Rotate left.
   */
  rotateLeft:function() {
    this.rotateZ(-90);
  },
  
  /**
   * Rotate right.
   */
  rotateRight:function() {
    this.rotateZ(90);
  },
  rotateZ:function(rotation) {
    this.engine.rotation.translate(new Point(rotation,rotation,rotation));
    this.render();
  },

  zoom:function(factor) {
    this.engine.scaling.scale(new Point(factor,factor,factor));
    this.render();
  },

  render:function() {
    this.engine.render();
  },
  
  
  /**
   * Starting the drag.
   */
  handleStartDrag:function(e) {
    if(this.blocked) return;
    
    
    this.startDragPoint = this.engine.getViewPointForEvent(e);
    this.dragStartTime = (new Date()).getTime();    
    $(this.engine.element).bind('mouseover', $.proxy(this.handleCheckDrag, this));
    e.preventDefault();
  },
  
  /**
   * 
   */
  handleCheckDrag:function(e) {
    $(this.engine.element).bind('mouseup', $.proxy(this.handleStopDrag, this));
    var time = (new Date()).getTime() - this.dragStartTime;
    var point = this.engine.getViewPointForEvent(e);
    
   
    if(PointUtil.distance(this.startDragPoint, point) > 10) {
     this.dragStarted = true;
     this.engine.element.addClass('drag');
     this.moveByEvent(e);
    }

  },

  /**
  * Move the engine.
  */
  moveByEvent:function(e) {
    var stopDragPoint = this.engine.getViewPointForEvent(e);
    var point = PointUtil.difference(stopDragPoint, this.startDragPoint);

    this.engine.translation.translate(point);
    // this.engine.render();
    this.startDragPoint = stopDragPoint;
  },



  /**
  * Stopping the drag.
  */
  handleStopDrag:function(e) {
    $(this.engine.element).unbind('mouseup', $.proxy(this.handleStopDrag, this));
    if(this.dragStarted) {
      this.engine.element.removeClass('drag');
      this.moveByEvent(e);
      this.render();
    }
    $(this.engine.element).unbind('mouseover', $.proxy(this.handleCheckDrag, this));
    this.dragStarted = false;
  },
  
  
  
  
  block:function() {
    console.info("Gridcontroller blocked");
    this.blocked = true;
  },
  
  unblock:function() {
    
    this.blocked = false;
  }
  
  
});