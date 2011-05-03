var Category = Class.extend({
  init:function(name, items) {
    this.name = name;
    this.items = items;
  },
  getName:function() {
    return this.name;
  },
  getItems:function() {
    return this.items;
  }
});