//= require <lib/models/constraint>
//= require <lib/views/constraint_view>
/**
 * Constraints controller takes care of constraints.
 */
var ConstraintsController = Controller.extend({
  init:function() {
    this.constraints = {};
    this.constraintViews = {};
  },
  
  /**
   * Add a constraint to the constraints.
   * @param options - must contain an element item
   */
  addConstraint:function(constraint, options) {
    this.constraints[constraint.id] = constraint;
    this.constraintViews[constraint.id] = new ConstraintView(constraint, options.element);
  },
  
  
  /**
   * Returns the constraint by original id.
   */
  getConstraintById:function(id) {
    return this.constraints[id];
  }
  
});


