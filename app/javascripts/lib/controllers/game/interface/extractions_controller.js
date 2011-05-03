
/**
 * The extractions submenu is controlled in this class.
 */
var ExtractionsController = Controller.extend({
  init:function(element) {
    this.element = element;
  },
  activate:function() {
    if(!this.activated) {
      console.info(this.element);
      this.element.html("jo")
      this.activated = true;
    }
  }
});