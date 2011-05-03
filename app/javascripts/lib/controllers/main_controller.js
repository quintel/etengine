//= require <mvcjs>
//= require <lib/controllers/constraints_controller>
//= require <lib/controllers/input_elements_controller>
//= require <lib/controllers/municipality_controller>
//= require <lib/controllers/output_elements_controller>
//= require <lib/controllers/transitionprice_controller>
//= require <lib/helpers/lockable_function>
//= require <lib/helpers/util>
//= require <lib/helpers/i18n>
//= require <lib/helpers/browser>

/**
 * In MainController all initialisation is done.
 *
 */
var MainController = Controller.extend({
  init:function() {
    this.initControllers();
    this.initEventListeners();
  },
  
  /**
   * Initializes all controllers.
   */
  initControllers:function() {
    this.inputElementsController = new InputElementsController();
    this.outputElementsController = new OutputElementsController();
    this.municipalityController = new MunicipalityController();
    this.transitionpriceController = new TransitionpriceController();
  },
  
  initOptimizer:function() {
    this.optimizerController = new OptimizerController();
  },
  
  
  initGame:function() {
    this.gameController = new GameController();
    
  },
  
  /**
   * Initialize all event listeners.
   */
  initEventListeners:function() {
    //this.inputElementsController.addEventListener("change", $.proxy(this.handleInputElementsUpdate, this));
    this.inputElementsController.addEventListener("change", $.proxy(this.handleInputElementsUpdate, this));
  },
  
  /**
   * Set the update in a cancelable action
   */
  handleInputElementsUpdate:function() {
    var fun = $.proxy(this.doUpdateRequest, this);
    var lockable_function = function() { LockableFunction.deferExecutionIfLocked('update', fun)};
    Util.cancelableAction('update',  lockable_function, {'sleepTime':500});
  },
  
  
  /**
   * Get the value of all changed sliders. Get the chart. Sends those values to the server.
   */
  doUpdateRequest:function() {
    var dirtyInputElements = this.inputElementsController.getDirtyInputElements();
    
    if(dirtyInputElements.length == 0)
      return;
    
    window.App.call_api(this.inputElementsController.getApiUpdateValueString());
    
    //var currentOutputElement = this.outputElementsController.getCurrentOutputElement();
    //var url;
    //if(currentOutputElement) {
    //  url = "/query/update" + "?output_element_id=" + currentOutputElement.id + "&" + this.inputElementsController.getUpdateValueString();
    //  this.outputElementsController.outputElementViews[currentOutputElement.id].setLoading();
    //} else {
    //  url = "/query/update" + "?output_element_id=33&" + this.inputElementsController.getUpdateValueString();
    //}  
    // lockable function
    //LockableFunction.setLock('update');
    //
    //$.ajax({ 
    //  url: url +"&t="+Util.timestamp(), // appending now() prevents the browser from caching the request
    //  method: 'get', // use GET requests. otherwise chrome and safari cause problems.
    //  complete: $.proxy(function() {
    //    if(currentOutputElement)
    //      this.outputElementsController.outputElementViews[currentOutputElement.id].removeLoading();
    //    LockableFunction.removeLock('update');
    //    // used by user tracking
    //    $("body").trigger("dashboardUpdate");
    //  }, this)
    //});
    // remove all dirtyness
    this.inputElementsController.clean();
  }
});


