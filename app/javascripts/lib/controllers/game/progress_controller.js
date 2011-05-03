/**
 * Progress is controlled here. The engine dispatches PROGRESS events. 
 */
var ProgressController = Controller.extend({

  /**
   * Initialization of the progress controller.
   * 
   * @param [IsometricEngine] The 3d engine.
   */
  init:function(engine) {
    this.engine = engine;
    this.engine.addEventListener("PROGRESS", $.proxy(this.setProgress, this));
  },

  /**
   * Set the element that is used to plot the progress in.
   */
  setElement:function(element) {
    this.element = element;
    this.progressElement = $('<div>').addClass('progress');
    this.totalProgress = $('<div>').addClass('totalProgress');
    this.totalProgress.append(this.progressElement);
    this.element.append(this.totalProgress);
    this.progressText = $('<span>').addClass('progressText');
    this.element.append(this.progressText)
  },
  
  /**
   * This function is invoked when a progress event is thrown.
   */
  setProgress:function(progress) {
    // show it if it's hiddden
    if(this.element.css('display') == 'none') {
      this.element.show();
    }
    
    var percentage = (progress.amt / progress.total * 100);
    this.progressElement.css('width', percentage + '%');

    // if done, hide the element after some seconds.
    if(percentage == 100) {
      setTimeout($.proxy(function() {
        this.element.hide();  
      }, this), 100); 
    }
    this.progressText.html((percentage).toFixed(1) + "%" + " " + progress.message);
  }
});
  