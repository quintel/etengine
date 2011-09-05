$(document).ready(function() {
  $("#panel").resizable({
    handles: 'e'
  });

  $('input#search').keyup(function(ev) {
    if(ev.keyCode == 27) { $(this).val(''); }
    var search = $(this).val();
    var cookie_key = $(this).attr('data-search_scope');

    if (cookie_key != undefined) {
      $.cookie(cookie_key, search);
    }
    
    var condition = $.map( search.split(' '), function(el) {
      if (el != "") { return "[data-search*="+el+"]"; }
    }).join('');
    
    $('.tree li').hide();
    $('.tree li'+condition).show();
  });
      
  var stored_search = $.cookie($('input#search').attr('data-search_scope'));
  $('input#search').val(stored_search).keyup();

  $('.gql_operator').mouseover(function(ev) {
    var statement = $(this).next().text();
    var query = $(this).text() + statement;
    $(this).next().css('background', '#666');
  });
  
  $('.gql_operator').mouseout(function(ev) {
    $(this).next().css('background', 'none');
  });

});
