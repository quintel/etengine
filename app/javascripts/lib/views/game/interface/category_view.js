var CategoryView = EventDispatcher.extend({
  init:function(category) {
    this.category = category;
    this.element = $("<div>").addClass('category');

    this.headerElement = $("<div>").html(category.getName()).addClass('categoryHeader');;
    this.headerElement.bind('click', $.proxy(this.toggleItems,this));
    this.element.append(this.headerElement);
    
    this.itemsElement = $("<div>").addClass('items');
    this.element.append(this.itemsElement);
    
  },
  toggleItems:function() {
    this.dispatchEvent("CLICKED", this);
  },
  showItems:function() {
   this.visible = true;
    this.initItems();
    this.itemsElement.show();
  },
  
  hideItems:function() {
    this.visible = false;
    this.itemsElement.hide();
  },
  
  initItems:function() {
    if(this.initialized)
      return;
    var el = $('<div>').addClass('items');
    for(var i = 0; i < this.category.getItems().length; i++) {
      var catItemElement = new CategoryItemView(this.category.getItems()[i]);
      this.itemsElement.append(catItemElement.element);
      catItemElement.addEventListener("DRAG_START", $.proxy(function(el) {this.dispatchEvent("CATEGORY_ITEM_DRAG_START", el)},this));
    }
    this.initialized = true;
  }
  
});