
//= require <lib/models/game/category>
//= require <lib/models/game/category_item>
//= require <lib/models/game/library>

//= require <lib/views/game/interface/category_view>
//= require <lib/views/game/interface/category_item_view>


/**
 * The first submenu, that of the powerplants is controlled here.
 */
var PowerPlantsController = Controller.extend({
  
  /**
   * Initialize this controller.
   * 
   * @params [DOMElement] the element that is used to draw the submenu in.
   */
  init:function(element) {
    this.element = element;
  },
  
  /**
   * Called when the submenu is activated.
   */
  activate:function() {
    if(!this.activated) {     
      this.buildCategories();
      this.activated = true;
    }
  },

  /**
   * Get the categories and their category items.
   */
  getCategories:function() {
    return Library;
  },
  
  /**
   * Build the categories.
   */
  buildCategories:function() {
    var categories = this.getCategories();
    
    this.categoryViews = [];
    for(var i = 0; i < categories.length; i++) {
      var catElement = new CategoryView(categories[i]);
     
      catElement.addEventListener("CATEGORY_ITEM_DRAG_START", $.proxy(ETM.gameController.itemsController.handleCatItemElementClicked, ETM.gameController.itemsController))
      catElement.addEventListener("CLICKED", $.proxy(this.handleCatElementClicked, this))
      this.element.append(catElement.element);
      this.categoryViews.push(catElement);
    }
  },
  
  /**
   * Called when a category is clicked.
   */
  handleCatElementClicked:function(catElement) {
    for(var i = 0; i < this.categoryViews.length; i++) {
      if(this.categoryViews[i] == catElement && !catElement.visible) {
        this.categoryViews[i].showItems();
      } else {
        this.categoryViews[i].hideItems();
      }
    }
  },
  
  
  
  
  
});













