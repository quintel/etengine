$(document).ready(function() {

  $('input#search').keyup(function(ev) {
    var search = $(this).val();
    $.cookie($(this).attr('data-search_scope'), search);
    var condition = $.map(search.split(' '), function(el) {
      if (el != "")
      return "[data-search*="+el+"]";
      }).join('');
      console.log(condition);
      $('.tree li').hide();
      $('.tree li'+condition).show();
    })
    var stored_search = $.cookie($('input#search').attr('data-search_scope'));
    $('input#search').val(stored_search).keyup();

    
    $('.gql_operator').click(function(ev) {
      window.open()
    })
    

    $('.gql_operator').mouseover(function(ev) {
      // E.g.: VALUE( ... )
      // operator: VALUE
      // statement: ( ...)
      var statement = $(this).next().text();
      var query = $(this).text() + statement;
      $(this).next().css('background', '#666');
    })      
    $('.gql_operator').mouseout(function(ev) {
      $(this).next().css('background', 'none');
    })

})
