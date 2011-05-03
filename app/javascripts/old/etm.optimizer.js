function detect_checked_checkboxes(table_id){
  var out = [];
  var rows = $('#' + table_id + ' tr');
  rows.each(function(){
    var checkbox = $("input[type='checkbox']", this);
    if (checkbox.attr('checked') == true){
      out.push($(this).attr('id'));
    }
  });
  return out.join(',');
}

function parse_checkboxes(checkbox_ids){
  $.each(checkbox_ids, function(key, checkbox_id) { 
    var checkbox = $("#"+checkbox_id+"_include");
    checkbox.attr('checked', true);
  });
}

function show_checked_elements(){
  alert(detect_checked_checkboxes('input_elements'), 'Copy-paste this list and save it whereever you like!');
}

function alert(msg){
  $('#input_output_for_save_load').html(msg);
}

function input_checked_elements(){
  var input_string = prompt('Please provide a list that you got from \'save current\'','');
  var out = [];
  out = input_string.split(',');
  parse_checkboxes(out);
}

