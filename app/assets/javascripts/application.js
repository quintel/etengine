// This is the global JS for ETE. The only thing kept aside is the chart
//
//= require jquery
//= require jquery-ui
//= require jquery_ujs
//= require bootstrap
//= require jquery.tablesorter.min
//= require highlight.pack
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

  $('pre.highlight').each(function(i, block) {
    hljs.highlightBlock(block);
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

  // Present / Future Edge Swapper

  function supports_html5_storage() {
      try {
          return 'localStorage' in window && window['localStorage'] !== null;
      } catch (e) {
          return false;
      }
  }

  $('.future-edges h2 a, .present-edges h2 a').click(function(event) {
    $('.future-edges').toggle();
    $('.present-edges').toggle();

    if (supports_html5_storage()) {
        localStorage.setItem(
            'presentEdges', $('.present-edges').is(':visible')
        );
    }

    event.preventDefault();
  });

  if (supports_html5_storage()) {
      if (localStorage.getItem('presentEdges') === 'true') {
          $('.future-edges h2 a').click();
      }
  }
});
