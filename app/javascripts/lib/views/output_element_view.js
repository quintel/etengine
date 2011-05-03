/**
 * OutputElementView
 * Controls the view of a single output element.
 *
 */
var OutputElementView = View.extend({
  init:function(output_element, element) {
    this._super(output_element, element);
  },  
  /**
   * Is called when something in the constraint model changed.
   * @override
   */
  updateHandler:function() {
    
  },
  
  setLoading:function() {
    $('#chart_loading').show();
  },
  removeLoading:function() {
    $('#chart_loading').hide();
  }
  
  
  
  
  
  
});