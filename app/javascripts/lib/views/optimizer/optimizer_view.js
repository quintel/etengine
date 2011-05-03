var OptimizerView = View.extend({
  init:function(element, button) {
    //this._super(element, element);
    this.button = button;
    this.element = element;
    this.text = "";
  },
  
  /**
   * Is called when something in the constraint model changed.
   * @override
   */
  updateHandler:function() {
    console.info("Updating input element row view.")
  },
  
  setStarted:function() {
    this.addText("Started");
    this.button.attr('value', 'Stop optimizer');
  },
  
  setStopped:function() {
    this.addText("Stopped")
    this.button.attr('value', 'Resume optimizer');
  },
  reset:function() {
    this.button.attr('value', 'Start optimizer');
  },
  addStopButton:function() {

  },
  addText:function(text) {
    this.text += "<br />" + text;
    this.element.html(this.text);
  }

  
});
