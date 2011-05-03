//= require <lib/views/game/progress_event>
//= require <lib/views/game/isometric_engine/isometric_grid>
//= require <lib/views/game/isometric_engine/point>
//= require <lib/views/game/isometric_engine/path>
//= require <lib/views/game/isometric_engine/polygon>
//= require <lib/views/game/isometric_engine/movieclip>


/**
 * === Isometric 3D engine.
 * 
 * This engine is based on Raphael. It can render simple polygons
 *  and place isometric movieclips.
 * 
 * == Isometric perspective
 * The engine has a isometric perspective. All elements that are added to the 
 * engine are "real coordinates", that is: an xyz point, with z pointing up.
 *
 *    z
 *    |     y
 *    |   /   
 *    | /        
 *    0 ______ x
 *   
 * All transformations done on points are in this coordinate system.
 *
 * When the enginge renders, it translates those real coordinates back to 
 * screen coordinates.
 *
 * e.g. the real coordinate (1,1,1) is in view coordinates (0.5, 1) or 
 * something (not right!), only 2 axis, a screen only has 2 right :-P.
 *
 * If you want to translate a real coordinate to a view coordinate: 
 * 
 *    => use #transformToViewCoordinates(new Point(1,1,0)) => new Point(0.5, 1 ).
 * 
 * if you want to know a point on screen, which real coordinate it is, 
 * we then assume z = 0 :  
 * 
 *    => use #transformToRealCoordinates(new Point(0.5, 1 )) => new Point(1,1,0).
 *
 * == Rendering
 *
 * Rendering is done in steps. It's broken in steps to prevent the browser 
 * from spinning. These steps are rendered sequentially using setTimeout. 
 * 
 * == Grid
 * 
 * The isometric grid is the base of interactions with the engine. 
 * Elements can be placed on the grid. 
 * 
 *
 * @author Jaap van der Meer
 */

var IsometricEngine = EventDispatcher.extend({
  xCos:Math.cos(0.46365),
  ySin:Math.sin(0.46365),
  
  init:function(elementId, width, height, isoMetric) {
    this.elementId = elementId;
    this.polygons = [];
    this.movieClips = [];
    this.origWidth = width;
    this.origHeight = height;
    this.isoMetric = true;
    this.rotation = new Point(0,0,0);
    this.scaling = new Point(5,5,5);
    this.translation = new Point(0,0,0);
    this.mode = 'normal';
  },
  
  /**
   * Initialize all event listeners.
   */
  initEventListeners:function() {
    this.element = $('#' + this.elementId);
    this.initDimensions();
    this.dispatchEvent("INITIALIZED");
    $(window).bind('resize', $.proxy(this.handleResize, this));

  },
  
  
  
  /**
   * Handle the resize
   */
  handleResize:function() {
    this.initDimensions();
    this.render();    
  },
  
  /**
   * Initialize the dimensions.
   */
  initDimensions:function() {
    this.width = this.origWidth == '100%' ? this.element.width() : this.width;
    this.height = this.origHeight == '100%' ? this.element.height() : this.height;
  },
  
  /**
   * Get the width of the engine, the width is decided at initialization.
   */
  getWidth:function() {
    return this.width;
  },

  /**
   * Get the coordinate of an event in view coordinates.
   */
  getViewPointForEvent:function(e) {
    var screenX = e.pageX - this.element.offset().left;
    var screenY = e.pageY - this.element.offset().top;
    return new Point(screenX, screenY);
  },
  
  
  
  /**
   * Get the coordinate of an event in view coordinates and transform
   * this point to real coordinates.
   */
  getRealPointForEvent:function(event) {
    return this.transfomToRealCoordinates(this.getViewPointForEvent(event));
  },
  
  /**
   * Add a movieclip to the engine.
   */
  addMovieClip:function(mc) {
    this.movieClips.push(mc);
    return mc;
  },
  
  removeMovieClip:function(mc) {
    // this.element.remove(mc.element);
    mc.element.remove();
    return this.movieClips.splice(this.movieClips.indexOf(mc), 1);
  },
  
  /**
   * Add polygons to be rendered to the engine
   */
  addPolygon:function(path, attr) {
    this.polygons.push(new Polygon(path, attr));
  },
  
  
  /**
   * Render the polygons that are currently in the engine.
   */
  render:function(objects) {
    if(!this.initialized) {
      this.initEventListeners();
      this.initialized = true;
    }
    
    for(var i = 0; i < this.movieClips.length; i++) {
       this.movieClips[i].addedToStage = false;
    }
    
    this.renderSteps = [];    
    this.addRenderStep("Setting up Raphael", function() {
      this.element.empty();
      this.R = Raphael(this.elementId, this.width, this.height);
    });
    
    this.addRenderStep("Rendering polygons", function() {
      this.renderPolygons();      
    });

 
    this.addRenderStep("Rendering movieclips", function() {
      this.renderMovieClips();
    });

    this.startRendering();
  },
  
  
  /**
   * As explained above the rendering is done in steps. The main reason
   * for this is that progress events can be throwed in the middle of rendering
   * and that the browser won't freeze.
   *
   * @param description This is used when throwing the progress event
   * @param fun The function that is done when rendering this thing.
   */
  addRenderStep:function(description, fun) {    
    fun = $.proxy(fun, this);
    this.renderSteps.push({description:description, fun:$.proxy(function(f) {
      return function() {
        f.call(this);
        this.renderNextStep();
      }
    }(fun), this)});
  },
  
  /**
   * Initialize the rendering and start calling the chain of steps.
   */
  startRendering:function() {
    this.totalRenderSteps = this.renderSteps.length;
    this.renderStep = 0;
    this.renderNextStep();
  },

  /**
   * Will dispatch a progress event and after set an timeout of just 1 ms, to 
   * call the next  render step.
   */  
  renderNextStep:function() {
    var step = this.renderSteps[this.renderStep++];
    if(step) {  
      this.dispatchEvent("PROGRESS", new ProgressEvent(this.renderStep, this.totalRenderSteps+1, step.description));
      setTimeout( $.proxy(step.fun,this), 1);
    } else {
      this.dispatchEvent("PROGRESS", new ProgressEvent(this.renderStep, this.totalRenderSteps+1, "Done"));
    }
  },
  
  /**
   * Render all polygons in the engine.
   */
  renderPolygons:function() {
    for(var i = 0; i < this.polygons.length; i++) {
      var polygon = this.polygons[i];
      this.renderPolygon(polygon);
    }
  },
  
  /**
   * Render one polygon
   *
   * @param [Polygon] The polygon to be rendered.
   */
  renderPolygon:function(polygon) {
    var svgPathStr = "";
    var svgPath = [];
    for(var k = 0; k < polygon.path.points.length; k++) {      
      var point = this.transformToViewCoordinates(polygon.path.points[k])
      if(k == 0) {
        svgPath.push("M" + point.x + "," + point.y);
      } else {
        svgPath.push("L" + point.x + "," + point.y);
      }
    }
  
    svgPathStr += svgPath.join(" ") + "";  
    polygon.rendered = this.R.path(svgPathStr).attr(polygon.attr);
  },
  
  /**
   * Render all movieclips in the engine.
   *
   * @param [Polygon] The polygon to be rendered.
   */
  renderMovieClips:function() {
    for(var i = 0; i < this.movieClips.length; i++) {
      var mc = this.movieClips[i];
      var point = mc.getPoint();
      
      var imageWidth = (mc.getImageWidth() * this.scaling.x);
      var imageHeight = (mc.getImageHeight() * this.scaling.y);
      var topOffSett = (mc.getTopOffset() * this.scaling.y);
      
      var transformedPoint = this.transformToViewCoordinates(point);
      mc.element.css('position','absolute');
      mc.element.css('top', transformedPoint.y - topOffSett);
      mc.element.css('left', transformedPoint.x - imageWidth / 2);
      mc.image.css('width', imageWidth);
      if(!mc.addedToStage) {
        this.element.append(mc.element);
        mc.addedToStage = true;
        mc.dispatchEvent("ADDED_TO_STAGE", mc);
      }

    }
  },
  
  /**
   * Transform a point to view coordinates. That is: 
   * what is this point on screen in the "real" 3d world if you
   * put the point with z=0?
   * 
   * @param [Point] The point to be transferred.
   */
  transformToViewCoordinates:function(point) {
    point = point.clone();
    point.rotateZ(this.rotation.z);
    point.scale(this.scaling);
    point.translate(this.translation);
    if(this.isoMetric) {
      point.rotateZ(-45);
      // point.translate(new Point(this.width/2,this.height/2, 0))
      var x = this.getWidth()/2 + (point.x - point.y)*this.xCos;
      // var y = this.height/2 - (point.x + point.z)*;
      var y = this.height/2 + (point.x + point.y) *this.ySin + point.z;
      var z = 0;

      return new Point(x, y, 0);
    } else {
      var x = this.getWidth()/2 + (point.x);
      // var y = this.height/2 - (point.x + point.z)*;
      var y = this.height/2  + (point.y);
      var z = 0;
      return new Point(x, y, z);
    }
  },
  
  /**
   * Transform a real point to view coordinates.
   *
   * @param [Point] The point to be transformed.
   */
  transfomToRealCoordinates:function(point) {
    point = point.clone();

    //
    if(this.isoMetric) {
      var y = (((point.y - this.height/2) / this.ySin) - ((point.x - this.getWidth()/2) / this.xCos)) / 2;
      var x = (((point.y - this.height/2) / this.ySin) + ((point.x - this.getWidth()/2) / this.xCos)) / 2;
      point = new Point(x, y, z);
      point.rotateZ(45);
    } else {
      var x = point.x - this.getWidth()/2;
      var y = point.y - this.getWidth()/2;
      point = new Point(x,y);

    }
    point.translate(new Point(-this.translation.x, -this.translation.y, -this.translation.z));
    point.rotateZ(-this.rotation.z);
    point.scale(new Point(1/this.scaling.x, 1/this.scaling.y, 1/this.scaling.z));
    
    return point;
  }
  
  
});











