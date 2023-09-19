import Sortable from 'sortablejs';
import jQuery from 'jquery';
import "bootstrap";
import "controllers"

global.$ = global.jQuery = jQuery;

window.addEventListener('DOMContentLoaded', (event) => {

    $('.js-sortable').each(function() {
        initializeSortable($(this).attr('id'))
    })

    $('textarea[data-cms-cm-readOnly=true]').each(function () {
        let editor = $(this).next('.CodeMirror')[0].CodeMirror;
        editor.options.readOnly = 'nocursor';
    })
})

$(document).on("turbo:load", () => {
    $('[data-violet-jsoneditor]').each(function() {
        const editor = new JSONEditor(this, {
            onChange: () => { setFields(this, editor.get()) }, 
            mode: `${this.dataset.mode || 'tree'}`
        })

        // set json
        const initialJson = {
            "Array": [1, 2, 3],
            "Boolean": true,
            "Null": null,
            "Number": 123,
            "Object": {"a": "b", "c": "d"},
            "String": "Hello World"
        }

        editor.set(initialJson)
        let existingValue = $(`#${this.dataset.target}`).val()

        if (existingValue) {
            let json = JSON.parse(existingValue)
            $(`#${this.dataset.target}`).val(existingValue)
            editor.set(json)
        } else {
            setFields(this, editor.get())
        }
        // get json
        const updatedJson = editor.get()
    })
});

function setFields(container, content) {
    $(`#${container.dataset.target}`).val(JSON.stringify(content))
}
    

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
      .children('.form-container')
      .each(function (index) {
        $(this)
          .find(".position_field").val(index)
      });
  }



require("../../common")
require("../../turbo")
