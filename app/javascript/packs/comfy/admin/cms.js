import Sortable from 'sortablejs';

window.addEventListener('DOMContentLoaded', (event) => {

    $('.js-sortable').each(function() {
        initializeSortable($(this).attr('id'))
    })

    $('.js-jsoneditor').each(function() {
        initializeJsonEditor($(this).attr('id'), $(this).attr('data-field-id'))
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


function initializeJsonEditor(containerId, fieldId) {
    const container = document.getElementById(containerId)
    const options = {onChange: () => { setFields() } }
    const editor = new JSONEditor(container, options)

    const initialJson = {}
    editor.set(initialJson)

    let existingValue = $('#' + fieldId).val()

    if (existingValue) {
        let json = JSON.parse(existingValue)
        editor.set(json)
    } else {
        setFields()
    }

    function setFields() {
        let str = JSON.stringify(editor.get())
        $('#' + fieldId).val(str)
    }

    const updatedJson = editor.get()
  }


function resetIndex(containerId) {
    $("#" + containerId)
      .children()
      .each(function (index) {
        $(this)
          .find(".position_field").val(index)
      });
  }
  