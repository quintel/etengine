var PlacedCategoryItem = Class.extend({
  init:function(catItem, mc) {
    this.catItem = catItem;
    this.mc = mc;
  },
  
  getCategoryItem:function() {
    return this.catItem;
  },
  
  getMC:function() {
    return this.mc;
  },
  
  /*
   * This really places the item on screen.
   *
   *
   */
  addedToStage:function() {
    this.catItem.addedToStage();
    
    /*
    var v = ETM.inputElementsController.inputElements[1].getAttribute('user_value');
    v += 0.5;
    ETM.inputElementsController.inputElements[1].setAttribute('user_value', v);
    ETM.inputElementsController.handleUpdate();
    */
  },
  
  
  remove:function() {
    this.catItem.removedFromStage();
    
    /*
    var v = ETM.inputElementsController.inputElements[1].getAttribute('user_value');
    v -= 0.5;
    ETM.inputElementsController.inputElements[1].setAttribute('user_value', v);
    ETM.inputElementsController.handleUpdate();
    */
  }
  
  
  
  
})