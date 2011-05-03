SelectableRowView = View.extend({
  /**
   * The initialization of a view. 
   * 
   * @param model(Model)        A model that this view is controlling.
   * @param element(DOMElement) The DOM Element this view will control.
   */
  init:function(model, element){
    this._super(model, element);
    this.element.click(jQuery.proxy(this.handleRowClick, this));
  },
  getCheckboxElement:function() {
    return $("input[type='checkbox']", this.element);
  },
  
  /**
   * @param value   true checks the checkbox, false enchecks it
   */
  setCheckboxValue:function(value) {
    this.getCheckboxElement().attr("checked", value ? "checked" : "");
  },
  getCheckboxValue:function() {
    return this.getCheckboxElement().attr("checked");
  },

  toggleSelection:function() {
    var checkboxElement = this.getCheckboxElement();
    this.setCheckboxValue(!this.getCheckboxValue());    
  },
  handleRowClick:function(event) {
    var excluded_targets = ['text','checkbox','select-one'];
    if(jQuery.inArray(event.target.type, excluded_targets) == -1) {
      this.toggleSelection();
    }
  }

});
