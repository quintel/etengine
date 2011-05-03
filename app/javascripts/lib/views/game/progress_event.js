var ProgressEvent = Class.extend({
  init:function(amt, total, message) {
    this.amt = amt;
    this.total = total;
    this.message = message;
  },
  
  isCompleted:function() {
    return this.amt == this.total;
  }
  
  
  
});