
function round_value(value) {
  return Math.round((100 * (value))*100)/100;
}

var show_introscreen = true;

// init reset button
$(document).ready(function() {
  $("a.reset").click(function(){
    var this_id = $(this).attr('id');
    reset_slider(this_id);
    return false;
  });
  
  $("input.pick_prediction").live('click',function () {
    var slider_id = $(this).parents('a:first').attr('id').match(/\d+$/);
    var prediction_id = $(this).attr('data-prediction_id');

    if ($(this).is(':checked')) {
      $.ajax({ 
        url: "/expert_predictions/set_prediction/"+slider_id+"?prediction_id="+prediction_id,
        method: 'get',// use GET requests. otherwise chrome and safari cause problems.
        async: false
      });
    }
    else {
      reset_slider(slider_id);
    }
  });
  
});


// show reset button on hover -- called when slider is updated
function enable_reset_button(id) {
  var reset_button = $("#reset_slider_"+ id);
  reset_button.show();

}

function reset_slider(id) {
  var start_value = $("#slider_" + id + " .start_value").html();
  update_slider(id, start_value);
  var reset_button = $("#reset_slider_"+ id);
  reset_button.hide();  
}

function update_share_sliders(value,group,post){
  var sliders = $("."+group+"_share_group");
  sliders.each(function(index, input_element) {
    update_slider(input_element.id.match(/\d+$/), value, post);
  });
}