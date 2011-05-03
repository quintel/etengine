
//= require <lib/controllers/generic/row_controller>
//= require <lib/models/optimizer/gquery_control>
//= require <lib/views/optimizer/gquery_control_view>

var GqueryControlsController = RowController.extend({
  init:function() {
    this._super({}, {}, 'gquery_control'); 
  },
  
  /**
   * @override
   */
  getObjectFromAjaxObject:function(object) {
    return object.gquery_control;
  }
  
});