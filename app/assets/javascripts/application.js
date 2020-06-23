// This is the global JS for ETE. The only thing kept aside is the chart
//
//= require jquery
//= require jquery-ui
//= require jquery_ujs
//= require bootstrap
//= require jquery.tablesorter.min
//= require highlight.pack
//= require jquery.floatThead.min
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
      location.href = "/inspect/"+data.id;
    })
  });

  var $table = $('.debug-table');

  $table.tablesorter();

  $table.floatThead({
    useAbsolutePositioning: true,
    scrollContainer: function($table){
      return $table.closest('.debug-table-wrapper');
    }
  });

  $('.table-raw-switcher button').click(function() {
    element = $(this);
    parent  = element.closest('.tal');

    parent.find('.table, .csv, .tsv, .txt').hide();
    parent.find('.' + element.data('show')).show();

    parent.find('button').removeClass('btn-primary disabled');
    element.addClass('btn-primary disabled');

    if(element.data('show') === 'table') {
      $table.floatThead('reflow');
    } else {
      $table.floatThead('destroy');
    }
  });

  $('textarea.txt, textarea.csv, textarea.tsv').click(function() {
    $(this).select();
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

  if (document.querySelector('.edge-flows')) {
    $('.edge-flows .nav-tabs a').click(function(event) {
      localStorage.setItem(
        'selectedPeriod', $(event.target).attr('href')
      );
    });

    var selectedPeriod = localStorage.getItem('selectedPeriod');
    if (selectedPeriod) {
        $('.edge-flows .nav-tabs a[href="' + selectedPeriod + '"]').click();
    }
  }

  $('.gql-debug #query').keyup(function(event) {
      if (event.ctrlKey && event.keyCode === 13) {
          $(event.target).parent('form').submit();
      }
  });
});
