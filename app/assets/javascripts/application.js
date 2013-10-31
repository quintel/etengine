// This is the global JS for ETE. The only thing kept aside is the chart
//
//= require jquery
//= require jquery-ui
//= require jquery_ujs
//= require bootstrap
//= require jquery.tablesorter.min
$(document).ready(function() {
  $("#api_scenario_selector select").change(function(e){
    e.preventDefault();
    var url = location.pathname;
    var tokens = url.split('/');
    tokens[2] = $("#api_scenario_id").val();

    var new_url = tokens.join('/');
    location.href = new_url;
  });

  $("#area_code_selector select").change(function(e){
    e.preventDefault();
    var params = {
        scenario: {
            area_code: $("#area_code_selector select").val(),
            source:    'ETEngine Admin UI'
        }
    };

    $.post('/api/v3/scenarios/', params, function(data, _ts, jqXHR) {
      location.href = "/data/"+data.id;
    })
  });

  $('.gql_operator').mouseover(function(ev) {
    var statement = $(this).next().text();
    var query = $(this).text() + statement;
    $(this).next().css('background', '#666');
  });

  $('.gql_operator').mouseout(function(ev) {
    $(this).next().css('background', 'none');
  });

  // sort by energy balance group and by position
  $('table#debug-calculation').tablesorter({ sortList: [[0,1], [4,0]] });

  // ETSource import pages

  var isImporting = false;

  $('.commit-group a.import').click(function(event) {
      if (isImporting) {
          return false;
      }

      isImporting = true;
      $(this).text('Importing...');
  });

  $('.compat-warning a.btn-success').click(function(event) {
      if (isImporting) {
          return false;
      }

      isImporting = true;
      var width = $(this).width()

      $(this).css('width', '' + width + 'px').text('Importing...');
  });
});
