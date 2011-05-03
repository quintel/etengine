/**
 * Constraint model. 
 */
var Constraint = Model.extend({
  init:function(attributes) {
    this._super(attributes);
  },
  getFormattedOutputScale:function() {
    return this.attributes['formatted_output_scale'];
  },
  getUnformattedOutput:function() {
    return this.attributes['unformatted_output'];
  },
  getOutput:function() {
    return this.attributes['output'];
  }
  
})