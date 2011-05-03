/**
 * InputElementRowView
 * Controls the view of a input element row in the view.
 *
 */
var SliderControlView = SelectableRowView.extend({
  init:function(model, element) {
    this._super(model, element);
  },
  
  /**
   * Is called when something in the constraint model changed.
   * @override
   */
  updateHandler:function() {
    $('.current_value', this.element).html( this.model.attributes.current_value )

  },
  

});
