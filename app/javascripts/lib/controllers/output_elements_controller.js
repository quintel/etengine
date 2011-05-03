//= require <lib/models/output_element>
//= require <lib/views/output_element_view>
/**
 * Output elements controller takes care of dealing with the output elements.
 */
var OutputElementsController = Controller.extend({
  init:function() {
    this.outputElements = {};
    this.outputElementViews = {};
    this.currentOutputElement = null;
  },
  
  /**
   * Add a output element to the output elements.
   * @param options - must contain an element item
   */
  addOutputElement:function(outputElement, options) {
    this.outputElements[outputElement.id] = outputElement;
    var outputElementView = new OutputElementView(outputElement, options.element);
    this.outputElementViews[outputElement.id] = outputElementView;
    this.currentOutputElement = outputElement;
  },

  /**
   * Gets the current output element
   * @param options - must contain an element item
   */
  getCurrentOutputElement:function() {
    return this.currentOutputElement;
  },
  
  /**
   * Returns the input element by original id.
   */
  getOutputElementById:function(id) {
    return this.outputElements[id];
  }
});


