require("./direct_upload");

window.previewFile = function previewFile(event, previewId) {
    var file = event.target.files[0];
    var attributeToBeChanged = 'src';
    var output;

    if (!file) {
      $('#' + previewId + '_video').hide();
      $('#' + previewId + '_img').hide();
      $('#' + previewId + '_download_link').hide();

      return;
    }

    if (file && file.type.match(/video/)) {
      output = $('#' + previewId + '_video');
      $('#' + previewId + '_img').hide();
      $('#' + previewId + '_download_link').hide();
    } else if (file && file.type.match(/image/)) {
      output = $('#' + previewId + '_img');
      $('#' + previewId + '_video').hide();
      $('#' + previewId + '_download_link').hide();
    } else {
      output = $('#' + previewId + '_download_link');
      output.text(file.name);
      attributeToBeChanged = 'href';
      $('#' + previewId + '_img').hide();
      $('#' + previewId + '_video').hide();
    }
    output.show();
    output.attr(attributeToBeChanged, URL.createObjectURL(file));
    output.on('load', function() {
      URL.revokeObjectURL(output[attributeToBeChanged]);
    })
}

window.requireCheckbox = function(className) {
    var checkboxes = $("." + className);
    if($(`.${className}:checked`).length>0) {
      checkboxes.removeAttr('required');
    }
    checkboxes.change(function(){
        if($(`.${className}:checked`).length>0) {
            checkboxes.removeAttr('required');
        } else {
            checkboxes.attr('required', 'required');
        }
    });
}

window.disableForm = function(form) {
  $(form).find(":submit").attr('disabled', 'disabled')
}

window.enableForm = function(form) {
  $(form).find(":submit").attr('disabled', false)
}
