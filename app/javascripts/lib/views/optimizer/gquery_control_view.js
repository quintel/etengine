//= require <lib/views/generic/selectable_row_view>
/**
 * GqueryControlView
 * Controls the view of a input element row in the view.
 *
 */
var GqueryControlView = SelectableRowView.extend({
  init:function(gqueryControl, element) {
    this._super(gqueryControl, element);
  },
  
  /**
   * Is called when something in the constraint model changed.
   * @override
   */
  updateHandler:function() {
    console.info("Updating gquery control value.");
    console.info(this.model.attributes)
  }
  
});
