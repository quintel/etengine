
// Dash ---------------------------------------------------------------

var Constraint = Backbone.Model.extend({
  initialize : function() {
    // we need this so that the following works: this.gquery.bind('change', this.update_value );
    _.bindAll(this, 'update_values');

    this.gquery = new Gquery({key : this.get('gquery_key')});
    // let gquery notify the constraint, when it has changed.
    this.gquery.bind('change', this.update_values );
    // this.update_values() will change attributes diff and result
    // => this will trigger a 'change' event on this object
    // ==> as ConstraintView binds the 'change' event, it will update itself.

    new ConstraintView({model : this});
  },

  calculate_diff : function() {
    if (this.previous('result') != undefined) {
      return this.get('result') - this.previous('result');
    } else {
      return 5;
    }
  },

  // Apply any last-minute fixes to the result.
  // Uses the future_value as default
  calculate_result : function() {
    var fut = this.gquery.get('future_value');
    var now = this.gquery.get('present_value');

    if (this.get('key') == 'total_primary_energy' ) {
      return calculate_performance(now, fut); }
    else { 
      return fut; 
    } 
  },

  // Update the result and diff, based on new gquery results
  update_values : function() {
    this.set({
      diff :   this.calculate_diff(),
      result : this.calculate_result() 
    });
  }
});

var Dashboard = Backbone.Collection.extend({
  model : Constraint
});
window.dashboard = new Dashboard();


// Charts ---------------------------------------------------------------

var ChartSerie = Backbone.Model.extend({
  initialize : function() {
    var gquery = new Gquery({key : this.get('gquery_key')});
    this.set({gquery : gquery});
  },
  
  result : function() {
    return this.get('gquery').result();
  }
});

var ChartSeries = Backbone.Collection.extend({
  model : ChartSerie
})

var ChartList = Backbone.Collection.extend({
  model : Chart,

  initialize : function() {
    //_.bindAll(this, 'change_chart');
    //this.bind('add', this.change_chart);
  },

  change : function(chart) {
    var old_chart = this.first();
    if (old_chart != undefined) {
      this.remove(old_chart);      
    }
    this.add(chart);
  },

  // this should be refactored into events. So we can trigger('loading') or 'loaded'
  show_loading : function() { $('#chart_loading').show(); },
  hide_loading : function() { $('#chart_loading').hide(); },

  load : function(chart_id) {
    if (this.first().get('id')+'' == chart_id + '') {
      // if chart_id == currently shown chart, skip.
      return;
    }
    window.charts.show_loading();
    var url = '/output_elements/'+chart_id+'.js?'+timestamp();
    $.getScript(url, function() { 
      window.charts.hide_loading();
      App.call_api('');
    });
  }
});
window.charts = new ChartList();

var Chart = Backbone.Model.extend({
  initialize : function() {
    this.series = new ChartSeries;
    //if (this.get('type') == 'bezier')
      new BezierChartView({model : this});
  },

  results : function() {
    return this.series.map(function(serie) { return serie.result(); });
  },
  colors : function() {
    return this.series.map(function(serie) { return serie.get('color'); });
  },
  labels : function() {
    return this.series.map(function(serie) { return serie.get('label'); });
  },
  values_present : function() {
    return _.map(this.results(), function(result) { return result[0][1]; });
  },
  values_future : function() {
    return _.map(this.results(), function(result) { return result[1][1]; });
  },
  values : function() {
    return _.flatten([this.values_present(), this.values_future()]);
  }

});

var ChartList = Backbone.Collection.extend({
  model : Chart
});
window.Charts = new ChartList;

// Slider ----------------------------------------------------------------------

