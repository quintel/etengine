// jqPlot doesn't work when chart_wrapper is inside a element that is hidden (display: none).
// Therefore, we have to move the .constraint_popup outside the view area (bottom: 8000px),
// and animate the shadowbox-outer to an opacity of 0.01, because fadeIn/fadeOut sets display: none at the end.
$(document).ready(function() {
  $('#constraints .constraint').click(function() {
    open_constraint_box(this);
  });

  $('.constraint_popup').bind('click', function() {
    close_all_constraint_boxes();
    return false;
  });
});



function open_constraint_box(constraint) {
  close_all_constraint_boxes();
  $('.constraint_popup', constraint).css('bottom', '80px');
  
  $('#shadowbox-outer', constraint).animate({opacity: 0.95}, 'slow');
  if ($('.loading', constraint).length == 1) {  
    $.get($(constraint).attr('rel')+"?t="+timestamp(), function(data) {
      $('#shadowbox-body', constraint).html(data);
    });      
  }
}

function close_all_constraint_boxes() {
  $('.constraint_popup').css('bottom', '8000px');
}
