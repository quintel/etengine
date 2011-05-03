//= require <lib/controllers/generic/collection_controller>
var RowController = CollectionController.extend({
  
  init:function(models, views) {
    this._super(models, views);
  },
  
  toggleAllViews:function() {
    for(var id in this.views) {
      this.views[id].toggleSelection();
    }
  },
  
  /**
   * @param state   true checks the checkbox, false enchecks it
   */
  setAllViews:function(state) {
    for(var id in this.views) {    
      this.views[id].setCheckboxValue(state);
    }
  },
  
  showSelectedViews:function() {
    for(var id in this.views) {    
      if(this.views[id].getCheckboxValue()) {
        this.views[id].element.show();
      } else {
        this.views[id].element.hide();
      }
    }
  },
  
  showAllViews:function() {
    for(var id in this.views) {    
      this.views[id].element.show();
    }
  },
  
  addModelWithView:function(model, view) {
    this.models[model.id] = model;
    this.views[model.id] = view;
  },
  
  updateRowControls:function(pSliderControls) {
    for(var i = 0; i < pSliderControls.length; i++) {
      var lSliderControl = pSliderControls[i].slider_control;
      this.sliderControls[lSliderControl.id].updateAttributes(lSliderControl);
    }
  },
  
});
  