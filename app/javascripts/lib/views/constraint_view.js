/**
 * ConstraintView
 * Controls the view of a single constraint.
 *
 */
var ConstraintView = View.extend({
  init:function(constraint, element) {
    this._super(constraint, element);
    this.setOldOutput();
  },
  
  /**
   * Sets the old value. This is used in calculation of the 
   * arrows.
   */
  setOldOutput:function() {
    this.oldOutput = this.model.getUnformattedOutput();
  },
  
  /**
   * Is called when something in the constraint model changed.
   * @override
   */
  updateHandler:function() {
    var diff = this.model.getUnformattedOutput() - this.oldOutput;
    this.updateArrows(diff);
    this.updateScale();
    this.updateOutput();
    this.setOldOutput();
  },
  
  /**
   * Updates the arrows, if the difference is negative .
   * @param diff - the difference of old_value and new_value.
   */
  updateArrows:function(diff) {
    var delta = 0.001;
    var arrow_element = $('.arrow', this.element);
    this.cleanArrows();
    
    var newClass;
    if(Math.abs(diff) > delta) {
      if(diff > 0) {
        newClass = 'arrow_up';
      } else if(diff < 0) {
        newClass = 'arrow_down';
      }
    } else {
      newClass = 'arrow_neutral';      
    }
    
    var arrowElement = $('.arrow', this.element);
    arrowElement.addClass(newClass);
    arrowElement.css('opacity', 1.0);
    // make sure the arrows take their original form after 30 seconds
    Util.cancelableAction("updateArrows" + this.model.id, $.proxy(function() {
      arrowElement.animate({opacity: 0.0}, 1000);
    },this), {'sleepTime': 30000});
    
  },
  /**
   * Clean the arrwos
   */
  cleanArrows:function() {
    var arrow_element = $('.arrow', this.element);
    arrow_element.removeClass('arrow_neutral');
    arrow_element.removeClass('arrow_down');
    arrow_element.removeClass('arrow_up');

  },
  
  /**
   * Updates the scale
   */
  updateScale:function() {
    if(this.model.getFormattedOutputScale() != null && this.model.getFormattedOutputScale() != "" )
      $('.header .scale', this.element).html("(" + this.model.getFormattedOutputScale() + ")");
  },
  /**
   * Updates the output
   */ 
  updateOutput:function() {
     $('strong', this.element).empty().append(this.model.getOutput());
     $('strong', this.element).attr('data-value');
     $('#shadowbox-body', this.element).html('<div class="loading">Loading...</div>');
  }
  
  
});