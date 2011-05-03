var ChartAreaView = Backbone.View.extend({
  
});



var BaseChartView = Backbone.View.extend({

  // was axis_values
  axis_scale : function() {
    var values_present = this.model.values_present();
    var values_future = this.model.values_future();

    if (this.model.get('percentage')) {
      return [0, 100];
    } 
    var axis_total_values = [
      _.reduce(values_present, function(sum, v) { return sum + (v > 0 ? v : 0); }, 0),
      _.reduce(values_future, function(sum, v) { return sum + (v > 0 ? v : 0); }, 0)
    ];
    
    return [0,this.axis_max_value(axis_total_values)];
  },

  // was axis_scale in ruby.
  // The axis value with which the chart should render.
  // It is basically the highest number + a bit of empty space.
  //
  axis_max_value : function(values) {
    var empty_space = 1.1;
    var total = _.max(values) * empty_space;
    var length = parseInt(Math.log(total) / Math.log(10));
    var tick_size = Math.pow(10, length) ;
    var ratio = (total / 5) / tick_size;

    var result;

    if (ratio < 0.025) 
      result = tick_size * 0.05;
    else if (ratio < 0.1)
      result = tick_size * 0.1;
    else if (ratio < 0.5)
      result = tick_size * 0.5;
    else if (ratio < 1)
      result = tick_size;
    else if (ratio < 1.5)
      result = tick_size * 1.5;
    else if (ratio < 2)
      result = tick_size * 2;

    return result * 5;
  }
})

var WaterfallChartView = BaseChartView.extend({
  initialize : function() {
    this.HEIGHT = '460px';
  }
});

var BezierChartView = BaseChartView.extend({


  initialize : function() {
    this.HEIGHT = '360px';
    _.bindAll(this, 'render');
    this.model.bind('change', this.render);
    this.series = this.model.series;
    this.model.view = this;
  },

  render : function() {
    var axis_scale = this.axis_scale();

    // SEB: maybe needs a better way to remove jqplot objects.
    //      => possible js memory leak
    $('#current_chart').empty().css('height', this.HEIGHT);
    InitializeBezier("current_chart", 
      this.model.results(), 
      true, 
      'PJ', 
      axis_scale, 
      this.model.colors(), 
      this.model.labels());
  }
});


var ConstraintView = Backbone.View.extend({
  initialize : function() {
    _.bindAll(this, 'render');
    this.id = "constraint_"+this.model.get('id');
    this.dom_id = '#'+this.id;
    this.element = $(this.dom_id);
    this.arrow_element = $('.arrow', this.dom_id);

    this.model.bind('change:result', this.render);
    this.model.view = this;
  },

  render : function() {
    $('strong', this.dom_id).empty().append(this.format_result());
    //this.updateArrows(this.model.get('diff'));
    return this;
  },

  // Formats the result of calculate_result() for the end-user
  format_result : function() {
    var result = this.model.get('result');
    var key = this.model.get('key');
    var result_rounded = this.round_number(result, 2);

    if (key == 'total_primary_energy' ) 
      return this.format_percentage(result, true);
    else if (key == 'co2_reduction' )
      return this.format_percentage(result, true);
    else if (key == 'net_energy_import') 
      return this.format_percentage(result); // TODO add :signed => false
    else if (key == 'renewable_percentage') 
      return this.format_percentage(result); // TODO add :signed => false
    else if (key == 'total_energy_cost')
      return this.format_with_suffix(result_rounded, 'EUR'); // Metric.currency((result / BILLIONS))
    else if (key == 'not_shown')
      return this.format_with_suffix(result_rounded, 'EUR'); // TODO round(2), add correct currency
    else if (key == 'targets_met') 
      return null; //Metric.out_of(result, Current.gql.policy.goals.length)
    else if (key == 'score')
      return parseInt(result);
    else
      return result;
  },

  round_number : function(value, round) {
    var rounded = Math.pow(10, round);
    return Math.round(value* (rounded))/rounded;
  },

  format_with_suffix : function(value, suffix) {
    return "" + value + suffix
  },

  format_percentage : function(value, signed) {
    //if (signed == undefined || signed == null) { signed = true };
    value = this.round_number(value, 2);
    //if (value > 0.0) { value = "+"+value; }
    return this.format_with_suffix(value, '%')
  },


  /**
   * Updates the arrows, if the difference is negative .
   * @param diff - the difference of old_value and new_value.
   */
  updateArrows:function(diff) {
    console.log(diff);
    if (diff == undefined || diff == null) { return false; }
    var delta = 0.001;
    var arrow_element = $('.arrow', this.dom_id);
    //this.cleanArrows();
    console.log(arrow_element)
    var newClass;
    if(Math.abs(diff) > delta) {
      if (diff > 0) { newClass = 'arrow_up';} 
      else if(diff < 0) { newClass = 'arrow_down'; }
    } else {
      newClass = 'arrow_neutral';      
    }
    
    arrowElement.addClass(newClass);//.css('opacity', 1.0);

    // make sure the arrows take their original form after 30 seconds
    //Util.cancelableAction("updateArrows" + this.model.get('id'), $.proxy(function() {
    //  arrowElement.animate({opacity: 0.0}, 1000);
    //}, this), {'sleepTime': 30000});
  },

  /**
   * Clean the arrwos
   */
  cleanArrows:function() {
    var arrow_element = $('.arrow', this.dom_id);
    arrow_element.removeClass('arrow_neutral');
    arrow_element.removeClass('arrow_down');
    arrow_element.removeClass('arrow_up');
  }
});
