import Sortable from 'sortablejs';

window.addEventListener('DOMContentLoaded', (event) => {

    $('.js-sortable').each(function() {
        initializeSortable($(this).attr('id'))
    })
})

function initializeSortable(containerId) {
    var el = document.getElementById(containerId);
    Sortable.create(el, {
        onEnd: function (evt) {
            resetIndex(containerId);
        },
    });
}

function resetIndex(containerId) {
    $("#" + containerId)
      .children()
      .each(function (index) {
        $(this)
          .find(".position_field").val(index)
      });
  }
  
window.previewFile = function previewFile(event, previewId) {
    var file = event.target.files[0]
    var output;
    if (file && file.type.match(/video/)) {
      output = $('#' + previewId + '_video');
      $('#' + previewId + '_img').hide();
    } else if (file && file.type.match(/image/)) {
      output = $('#' + previewId + '_img');
      $('#' + previewId + '_video').hide();
    }
    output.show();
    output.attr('src', URL.createObjectURL(file));
    output.on('load', function() {
      URL.revokeObjectURL(output.src)
    })
}