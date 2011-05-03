/**
 * Category Item View. 
 *
 */
var CategoryItemView = EventDispatcher.extend({
  init:function(categoryItem) {
    this.categoryItem = categoryItem;
    this.element = $("<div>").addClass('categoryItem');
    
    var _preventDefault = function(evt) { 
      evt.preventDefault(); 
    };
    var mc = categoryItem.createMovieClip();
    this.element.append(mc.element);
    this.element.append(categoryItem.getName());
    this.element.bind("selectstart", $.proxy(_preventDefault,this));
    mc.element.bind("mousedown", $.proxy(this.handleElementClicked,this));
    mc.element.bind("startdrag", $.proxy(this.handleElementClicked,this));
    this.element.bind("selectstart", $.proxy(this.handleElementClicked,this));
  },
  
  handleElementClicked:function(e) {
    this.dispatchEvent("DRAG_START", this);
    e.preventDefault();
  }
});

