/**
 * Transition Messages are controlled in this class.
 */
var TransitionpriceController = Controller.extend({
  init:function() {
    this.isShown = false;
    this.transitionprice = false;
  },
  
  /**
   * This is called after a message is shown. If the value changes, an ajax call
   * will be sent to the backend to let them know, the introduction has been shown.
   */
  setTransitionpriceMessageShown:function(value) {
    this.isShown = value;
  },

  /**
   * Show the message!
   */  
  showMessage:function() {
    return this.isTransitionprice && !this.isTransitionpriceMessageShown();
  }, 
  
  /**
   * Is the transitionprice message shown?
   */
  isTransitionpriceMessageShown:function() {
    return this.isShown;
  },
  
  /**
   * Set the transitionprice
   */
  setTransitionprice:function(transitionprice) {
    this.transitionprice = transitionprice;
  },
  
  /**
   * Returns true if we are inside a transitionprice.
   */
  isTransitionprice:function() {
    return this.transitionprice; //this.isTransitionprice;
  },
  
  /**
   * 
   */
  showTransitionpriceMessage:function() {
    alert(I18n.t('transition_prize.slider_locked_message'));
    this.setTransitionpriceMessageShown(true);
  }
});