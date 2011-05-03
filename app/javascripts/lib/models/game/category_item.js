var CategoryItemConstraint = {};
CategoryItemConstraint.ELECTRICITY_NETWORK = 'electricity_network';
CategoryItemConstraint.GAS_NETWORK = 'gas_network';
CategoryItemConstraint.GAS_FIELD = 'gas_field';

var CategoryItem = Class.extend({
  init:function(name, mcUrl,constraintedBy, updateFunction, inverseUpdateFunction) {
    this.name = name;
    this.mc = mcUrl;
    this.constraintedBy = constraintedBy;
    this.updateFunction = updateFunction;
    this.inverseUpdateFunction = inverseUpdateFunction;
  },
  getName:function() {
    return this.name;
  },
  createMovieClip:function() {
    return new MovieClip("/images/isometric/" + this.mc);
  },
  getConstraintedBy:function() {
    return this.constraintedBy;
  },
  
  addedToStage:function() {
    if(this.updateFunction)
      this.updateFunction.call(this);
  },
  
  removedFromStage:function() {
    if(this.inverseUpdateFunction)
      this.inverseUpdateFunction.call(this);
  }
  
});
