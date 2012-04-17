$(document).ready(function() {
  $('.gql_operator').mouseover(function(ev) {
    var statement = $(this).next().text();
    var query = $(this).text() + statement;
    $(this).next().css('background', '#666');
  });
  
  $('.gql_operator').mouseout(function(ev) {
    $(this).next().css('background', 'none');
  });

});
