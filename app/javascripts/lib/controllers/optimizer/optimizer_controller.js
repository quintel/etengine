//= require <lib/controllers/main_controller>
//= require <lib/views/optimizer/optimizer_view>
//= require <lib/controllers/optimizer/gquery_controls_controller>
//= require <lib/controllers/optimizer/slider_controls_controller>

/**
 * Constraints controller takes care of constraints.
 */
var OptimizerController = Controller.extend({
  STATE_STOPPED:0,
  STATE_STARTED:1,
  STATE_FINISHED:2, 
  
  init:function() {
    this.state = this.STATE_STOPPED;
    
    this.gqueryControlsController = new GqueryControlsController();
    this.sliderControlsController = new SliderControlsController();
    
  },
  
  initOptimizerView:function(element, button, form) {
    this.optimizerView = new OptimizerView(element, button);
    this.optimizerForm = form;
  },
    
  setOptimizerId:function(optimizerId) {
    this.optimizerView.addText("Optimizer created with id: " + optimizerId);
    this.optimizerId = optimizerId;
  },
  
  toggle:function() {
    if(this.state == this.STATE_STOPPED) {
      console.info("Starting")
      this.start();
    } else {
      console.info("Stoppimg")
      this.stop();
    }
  },
  
  start:function() {
    
    if(this.optimizerId) {
      this.doNextStep();
    } else {
      this.createOptimizer();
      this.optimizerView.setStarted();
    }
    this.state = this.STATE_STARTED;
  },
  
  createOptimizer:function() {
    this.optimizerView.addText("Creating optimizer");
    $.ajax({url:'/optimizer/optimizers.js', data:jQuery.param(jQuery(this.optimizerForm).serializeArray()), dataType:'script', type:'post', success: jQuery.proxy(this.handleCreateOptimizerFinished, this)});
  },
  
  handleCreateOptimizerFinished:function() {
    this.doNextStep();
  },
  stop:function() {
    this.optimizerView.setStopped();
    this.state = this.STATE_STOPPED;
  },
  
  doNextStep:function() {
    this.optimizerView.addText("Doing step for optimizer: " + this.optimizerId + "...");
    $.ajax({ url: "/optimizer/optimizers/" + this.optimizerId + ".js", context: document.body, success: jQuery.proxy(this.handleStepFinished, this) });
  },
  
  
  handleStepFinished:function() {
    this.optimizerView.addText("Step succesfully finished...");
    if(this.state == this.STATE_STARTED) {
      console.info("Doing next step...");
      this.doNextStep();
    } else if(this.state == this.STATE_STOPPED) {
      console.info("Stopped because of user canceling..");
    } else  {
      console.info("Finished no more steps...");
    }
    
  }, 
  
  setFinished:function() {
    this.optimizerView.addText("Finished");
    this.optimizerView.reset();
    this.optimizerId = null;
    this.state = this.STATE_FINISHED;
  },
  
  /**
   * Add a input element to the constraints.
   * @param options - must contain an element item
   */
  addSliderControl:function(sliderControl, options) {
    this.sliderControlsController.addModelWithView(sliderControl, new SliderControlView(sliderControl, options.element));
  },
  
  /**
   * Add a constraint to the constraints.
   * @param options - must contain an element item
   */
  addGqueryControl:function(gqueryControl, options) {
    this.gqueryControlsController.addModelWithView(gqueryControl,  new GqueryControlView(gqueryControl, options.element));
  },
  
  
  updateSliderControls:function(pSliderControls) {
    this.sliderControlsController.updateModels(pSliderControls);
  },
  
  
  updateGqueryControls:function(pGqueryControls) {
    this.gqueryControlsController.updateModels(pGqueryControls);
  },
  
  /**
   * Returns the constraint by original id.
   */
  getInputElementById:function(id) {
    return this.sliderControls[id];
  },

});
