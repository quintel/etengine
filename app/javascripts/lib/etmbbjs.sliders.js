//var SliderGroup = Backbone.Collection.extend({
//  model : Slider
//});
//
//var Slider = Backbone.Model.extend({
//  initialize : function() {
//    window.sliders.add(this);
//  }
//});
//
//var SliderList = Backbone.Collection.extend({
//  model : Slider
//});
//window.sliders = new SliderList;


//var InputElementView = Backbone.View.extend({
//  initialize:function(inputElement, element) {
//    this._super(inputElement, element);
//
//    var lSliderOptions = {  'reset_value':this.model.getAttribute('start_value'), 
//                            'value':this.model.getAttribute('user_value'), 
//                            'step_value':this.model.getAttribute('step_value'),
//                            'min_value': this.model.getAttribute('min_value'),  
//                            'max_value': this.model.getAttribute('max_value'), 
//                            'name': this.model.getAttribute('translated_name'), 
//                            'share_group': this.model.getAttribute('share_group'),
//                            'disabled': this.model.getAttribute('disabled'),
//                            'fixed': this.model.getAttribute("input_element_type") == "fixed" || this.model.getAttribute("input_element_type") == "fixed_share", 
//                            'formatter':this.getFormatter(),
//                            'precision':this.getPrecision(),
//                            'element':this.element, 
//                            'infoBox':{'disableDataBox':true}};
//    
//    this.sliderView = new AdvancedSliderView(lSliderOptions);
//    
//
//    // make the toggle red if it's semi unadaptable and in a municipality.
//    if(ETM.municipalityController.isMunicipality() && this.model.getAttribute("semi_unadaptable?"))  
//      this.sliderView.slider.toggleButton.element.addClass('municipality-toggle');
//  
//    this.initEventListeners();
//  },
//  
//  /**
//   * Init event listeners.
//   */
//  initEventListeners:function() {
//    this.sliderView.slider.sliderVO.addEventListener('update', $.proxy(function() { 
//      this.model.setAttribute("user_value", this.sliderView.slider.getValue(), {'noEvent':true});
//    }, this));
//    this.sliderView.getInfoBox().addEventListener('show', $.proxy(this.handleInputElementInfoBoxShowed, this));
//    this.sliderView.addEventListener('change', $.proxy(this.checkMunicipalityNotice, this));
//    this.sliderView.slider.addEventListener('change', $.proxy(this.handleSliderUpdate, this));
//    if(this.model.getAttribute("disabled_with_message?"))
//      this.sliderView.slider.sliderBar.element.bind('click', $.proxy(this.checkTransitionpriceNotice, this));
//  },
//  
//  getPrecision:function() {
//    var lPrecisionStr = this.model.getAttribute('step_value').toString() + "";
//    lPrecision = lPrecisionStr.replace('.', '').length - 1;
//    return lPrecision;
//  },
//  /**
//   * Returns a formatter on basis of the step_value.
//   */
//  getFormatter:function() {
//    var lPrecision = this.getPrecision();
//    switch(this.model.getAttribute('unit')) {
//      case "%":  
//        return SliderFormatter.numberWithSymbolFactory("%");
//      case "#":  
//        return SliderFormatter.numberWithSymbolFactory("#");
//      case "MW":  
//        return SliderFormatter.numberWithSymbolFactory("MW");
//      case "km2":  
//        return SliderFormatter.numberWithSymbolFactory("km2");
//      case "km":  
//        return SliderFormatter.numberWithSymbolFactory("km");
//      case "x":  
//        return SliderFormatter.numberWithSymbolFactory("x");
//      default:
//        return null;
//    }
//  },
//  
//  /**
//   * When the user does something on a slider this handler is invoked.
//   */
//  handleSliderUpdate:function() {
//    this.disableUpdate = true;
//    this.model.setAttribute("user_value", this.sliderView.slider.getValue());
//    this.sliderView.slider.setValue(this.model.getAttribute('user_value'), {'noEvent':true});
//    this.disableUpdate = false;
//  },
//  
//
//  /**
//   * This checks if the municipality message has been shown. It is has not been shown, show it!
//   */
//  checkMunicipalityNotice:function() {
//    if(this.model.getAttribute("semi_unadaptable?") && ETM.municipalityController.showMessage()) 
//      ETM.municipalityController.showMunicipalityMessage();
//  },
//  /**
//   * This checks if the transitionprice message has been shown. It is has not been shown, show it!
//   */
//  checkTransitionpriceNotice:function() {
//    if(ETM.transitionpriceController.showMessage()) 
//      ETM.transitionpriceController.showTransitionpriceMessage();
//  },  
//  /**
//   * Is called when something in the constraint model changed.
//   * @override
//   */
//  updateHandler:function() {
//    if(this.disableUpdate) return;
//
//    this.sliderView.setValue(this.model.getAttribute('user_value'), {'noEvent':true});
//  },
//
//  /**
//   * Is called when then infobox is clicked.
//   * @override
//   */
//  handleInputElementInfoBoxShowed:function() {
//    this.dispatchEvent('show', this);
//    if(this.model.getAttribute("has_flash_movie")) {
//      flowplayer('a.player', '/flash/flowplayer-3.2.6.swf');
//    }
//  }
//  
//  
//});
//
//
///**
// * Input elements controller takes care of dealing with the input elements.
// */
//var InputElementsController = Controller.extend({
//  init:function() {
//    this.inputElements = {};
//    this.inputElementViews = {};
//    this.shareGroups = {};
//    this.openInputElementInfoBox;
//  },
//  
//  /**
//   * Add a constraint to the constraints.
//   * @param options - must contain an element item
//   */
//  addInputElement:function(inputElement, options) {
//    this.inputElements[inputElement.id] = inputElement;
//    var inputElementView = new InputElementView(inputElement, options.element);
//    inputElementView.addEventListener('show', $.proxy(this.handleInputElementInfoBoxShowed, this));
//    this.inputElementViews[inputElement.id] = inputElementView;
//    inputElementView.sliderView.addEventListener("change", $.proxy(this.handleUpdate, this));
//    this.initShareGroup(inputElement);
//  },
//  
//  handleInputElementInfoBoxShowed:function(inputElementView) {
//    var infoBox = inputElementView.sliderView.getInfoBox();
//    if(this.openInputElementInfoBox && this.openInputElementInfoBox != infoBox)
//      this.openInputElementInfoBox.hide();
//    
//    this.openInputElementInfoBox = infoBox;
//  },
//  
//  
//  /**
//   * Initialize a share group for an input element if it has one.
//   */
//  initShareGroup:function(inputElement) {
//    var inputElementView = this.inputElementViews[inputElement.id];
//    var shareGroupKey = inputElement.getAttribute("share_group");
//    if(shareGroupKey && shareGroupKey.length) {
//      var shareGroup = this.getOrCreateShareGroup(shareGroupKey);
//      shareGroup.addEventListener("slider_updated",$.proxy(function(){inputElement.setDirty(true);},this)); //set all sliders from same sharegroup to dirty when one is touched
//      shareGroup.addSlider(inputElementView.sliderView.sliderVO);
//    }
//  },
//
//  /**
//   * Finds or creates the share group.
//   */
//  getOrCreateShareGroup:function(shareGroup) {
//
//    if(!this.shareGroups[shareGroup]) 
//      this.shareGroups[shareGroup] = new SliderGroup({'total_value':100}); // add group if not created yet
//    
//    return this.shareGroups[shareGroup];
//  },
//  /**
//   * Retrieve input elements which are dirty. 
//   */
//  getDirtyInputElements:function() {
//    var out = [];
//    for(var id in this.inputElements) {
//      var inputElement = this.inputElements[id];
//      if(inputElement.isDirty())
//        out.push(inputElement);
//    }
//    return out;
//  },
//  
//  /**
//   * Get the string which contains the update values for all dirty input elements.
//   */  
//  getUpdateValueString:function() {
//    var inputElements = this.getDirtyInputElements();
//    var out = [];
//    for(var i = 0; i < inputElements.length; i++) {
//      out.push(inputElements[i].id + "=" + inputElements[i].getAttribute("user_value"));
//    }
//    return out.join("&");
//  },
//  
//  /**
//   * Get the string which contains the update values for all dirty input elements.
//   */  
//  getApiUpdateValueString:function() {
//    var inputElements = this.getDirtyInputElements();
//    var out = [];
//    for(var i = 0; i < inputElements.length; i++) {
//      out.push("input["+inputElements[i].id+"]=" + inputElements[i].getAttribute("user_value"));
//    }
//    return out.join("&");
//  },
//  
//  /**
//   * Does a update request to update the values.
//   */  
//  handleUpdate:function() {
//    this.dispatchEvent("change");
//  },
//  
//  /**
//   * Remove dirtyness
//   */
//  clean:function() {
//    // remove the dirtyness
//    for(var id in this.inputElements) {
//      var inputElement = this.inputElements[id];
//      inputElement.setDirty(false);
//    }
//  },
//  
//  /**
//   * Returns the input element by original id.
//   */
//  getInputElementById:function(id) {
//    return this.inputElements[id];
//  }
//  
//
//});
//
//
//