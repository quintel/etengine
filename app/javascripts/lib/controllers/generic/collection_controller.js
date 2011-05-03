var CollectionController = Controller.extend({

  init:function(models, views) {
     this.models = {};
     this.views = {};
  },
  
  updateModels:function(pModels) {
    for(var i = 0; i < pModels.length; i++) {
      var lModel = this.getObjectFromAjaxObject(pModels[i]);
      this.models[lModel.id].updateAttributes(lModel);
    }
  },
  
  getObjectFromAjaxObject:function(object) {
    return object;
  }
})