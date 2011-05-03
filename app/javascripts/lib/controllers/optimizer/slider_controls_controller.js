//= require <lib/models/optimizer/slider_control>
//= require <lib/views/optimizer/slider_control_view>
var SliderControlsController = RowController.extend({
  init:function() {
    this._super({}, {}, 'slider_control'); 
  },
  
  /**
   * @override
   */
  getObjectFromAjaxObject:function(object) {
    return object.slider_control;
  }
  
  
});