
function calculate_performance(now, fut) {
  if (now != null || fut != null) {
    var performance = (fut / now) - 1;
    return performance;
  } else {
    return null;
  }
}

// APP / Session ---------------------------------------------------------------

window.AppView = Backbone.View.extend({
  API_URL : 'http://localhost:3100/api/v1',

  initialize : function() {
    _.bindAll(this, 'api_result');
    if ($.cookie('api_session_id') == null) {
      this.new_session();
    }
  },

  new_session : function() {
    var url = this.API_URL + "/api_scenarios/new.json?callback=?&";
    $.getJSON(url,
      function(data) {
        console.log(data.api_scenario.api_session_key);
        $.cookie('api_session_id', data.api_scenario.api_session_key);
        
      }
    );    
  },

  session_id : function() {
    return $.cookie('api_session_id');
  },

  call_api : function(input_params) {
    var url = this.API_URL + "/api_scenarios/"+this.session_id()+".json?callback=?&"+input_params;
    $.getJSON(url, {
        'result'   : Gqueries.keys()
      },
      this.handle_api_result
    );
  },

  handle_api_result : function(data) {
    var result   = data.result;   // The results of this request, as defined in "result" parameter

    $.each(result, function(gquery_key, value_arr) { 
      $.each(Gqueries.with_key(gquery_key), function(i, el) {
        el.set({
          present_year  : value_arr[0][0], present_value : value_arr[0][1],
          future_year   : value_arr[1][0], future_value  : value_arr[1][1]
        })
      });
    });
    window.charts.first().trigger('change');
  }
});

window.App = new AppView();



// API/Gquery ---------------------------------------------------------------

var Gquery = Backbone.Model.extend({
  initialize : function() {
    Gqueries.add(this);
  },

  result : function() {
    var present_value = this.get('present_value');
    var future_value = this.get('future_value');

    if (_.compact([present_value, future_value]) < 2) {
      console.warn('Gquery "'+this.get('key')+'" has undefined/null values. ' + present_value + '/' + future_value + "\n Reset to 0");
      present_value = 0;
      future_value = 0;
    }

    var result = [
      [this.get('present_year'), present_value], 
      [this.get('future_year'), future_value]
    ];

    return result;
  }
});

var GqueryList = Backbone.Collection.extend({
  model : Gquery,

  with_key : function(gquery_key) {
    return this.filter(function(gquery){ return gquery.get('key') == gquery_key; });
  },

  keys : function() {
    var keys = Gqueries.map(function(gquery) { return gquery.get('key') });
    return _.compact(keys);
  }
});
window.Gqueries = new GqueryList;

