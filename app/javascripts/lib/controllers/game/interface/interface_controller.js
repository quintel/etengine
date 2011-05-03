//= require <lib/controllers/game/interface/power_plants_controller>
//= require <lib/controllers/game/interface/extractions_controller>


/**
 * The interface is controlled in this class.
 */
var InterfaceController = Controller.extend({
  init:function() {

  },
  
  /**
   * Initialization of the submenus.
   * @param [DOMElement] The element in which the submenus are drawn.
   */
  initMenuItems:function(element) {
    this.menuItems = $('li', element);
    $('.header', this.menuItems).bind('click', $.proxy(this.handleMenuItemClicked, this));
    this.controllers = [];
    this.controllers[0] = new PowerPlantsController($('.content', this.menuItems[0]));
    this.controllers[1] = new ExtractionsController($('.content', this.menuItems[1]));
    this.closeMenuItems();
    this.openMenuItem(0);
  },
  
  
  /**
   * Handler for when a menu item is clicked
   * @param [MouseEvent] The event.
   */
  handleMenuItemClicked:function(e) {
    var index = $('.header', this.menuItems).index(e.currentTarget);
    this.closeMenuItems();
    this.openMenuItem(index);
  },

  /**
   * Close all menuites
   */
  closeMenuItems:function() {
    $('.content', this.menuItems).hide();
  },
  
  /**
   * Open a menu item
   * @param [Integer] The index of the menu item that must be opened.
   */
  openMenuItem:function(index) {
    this.controllers[index].activate();
    $('.content', this.menuItems[index]).show();
  }
  
  

});