//= require <lib/models/input_element>
//= require <lib/views/input_element_view>

/**
 * Input elements controller takes care of dealing with the input elements.
 */
var InputElementsController = Controller.extend({
  init:function() {
    this.inputElements = {};
    this.inputElementViews = {};
    this.shareGroups = {};
    this.openInputElementInfoBox;
  },
  
  /**
   * Add a constraint to the constraints.
   * @param options - must contain an element item
   */
  addInputElement:function(inputElement, options) {
    this.inputElements[inputElement.id] = inputElement;
    var inputElementView = new InputElementView(inputElement, options.element);
    inputElementView.addEventListener('show', $.proxy(this.handleInputElementInfoBoxShowed, this));
    this.inputElementViews[inputElement.id] = inputElementView;
    inputElementView.sliderView.addEventListener("change", $.proxy(this.handleUpdate, this));
    this.initShareGroup(inputElement);
  },
  
  handleInputElementInfoBoxShowed:function(inputElementView) {
    var infoBox = inputElementView.sliderView.getInfoBox();
    if(this.openInputElementInfoBox && this.openInputElementInfoBox != infoBox)
      this.openInputElementInfoBox.hide();
    
    this.openInputElementInfoBox = infoBox;
  },
  
  
  /**
   * Initialize a share group for an input element if it has one.
   */
  initShareGroup:function(inputElement) {
    var inputElementView = this.inputElementViews[inputElement.id];
    var shareGroupKey = inputElement.getAttribute("share_group");
    if(shareGroupKey && shareGroupKey.length) {
      var shareGroup = this.getOrCreateShareGroup(shareGroupKey);
      shareGroup.addEventListener("slider_updated",$.proxy(function(){inputElement.setDirty(true);},this)); //set all sliders from same sharegroup to dirty when one is touched
      shareGroup.addSlider(inputElementView.sliderView.sliderVO);
    }
  },

  /**
   * Finds or creates the share group.
   */
  getOrCreateShareGroup:function(shareGroup) {

    if(!this.shareGroups[shareGroup]) 
      this.shareGroups[shareGroup] = new SliderGroup({'total_value':100}); // add group if not created yet
    
    return this.shareGroups[shareGroup];
  },
  /**
   * Retrieve input elements which are dirty. 
   */
  getDirtyInputElements:function() {
    var out = [];
    for(var id in this.inputElements) {
      var inputElement = this.inputElements[id];
      if(inputElement.isDirty())
        out.push(inputElement);
    }
    return out;
  },
  
  /**
   * Get the string which contains the update values for all dirty input elements.
   */  
  getUpdateValueString:function() {
    var inputElements = this.getDirtyInputElements();
    var out = [];
    for(var i = 0; i < inputElements.length; i++) {
      out.push(inputElements[i].id + "=" + inputElements[i].getAttribute("user_value"));
    }
    return out.join("&");
  },
  
  /**
   * Get the string which contains the update values for all dirty input elements.
   */  
  getApiUpdateValueString:function() {
    var inputElements = this.getDirtyInputElements();
    var out = [];
    for(var i = 0; i < inputElements.length; i++) {
      out.push("input["+inputElements[i].id+"]=" + inputElements[i].getAttribute("user_value"));
    }
    return out.join("&");
  },
  
  /**
   * Does a update request to update the values.
   */  
  handleUpdate:function() {
    this.dispatchEvent("change");
  },
  
  /**
   * Remove dirtyness
   */
  clean:function() {
    // remove the dirtyness
    for(var id in this.inputElements) {
      var inputElement = this.inputElements[id];
      inputElement.setDirty(false);
    }
  },
  
  /**
   * Returns the input element by original id.
   */
  getInputElementById:function(id) {
    return this.inputElements[id];
  }
  

});


