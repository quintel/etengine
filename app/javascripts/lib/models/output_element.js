
/**
 * Input element model. 
 */
var OutputElement = Model.extend({
  init:function(attributes) {
    this._super(attributes);
  },
  
  
  /**
   * Does a update request to update the values.
   */  
  getUpdateUrl:function(options) {
    var lUrl = "/query/update/" + this.id;  
    return lUrl;
/*
    $.ajax({ 
      url: lUrl +"&t="+timestamp(), // appending now() prevents the browser from caching the request
      method: 'get',// use GET requests. otherwise chrome and safari cause problems.
      complete: function() {
        console.info("COMPLETE");
      }
    });
*/    
  }
  
})
