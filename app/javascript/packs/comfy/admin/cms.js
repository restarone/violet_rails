import Sortable from 'sortablejs';
import ctaSuccessHandler, { ctaSuccessHandlerRecaptchaV3 } from "../../website/call_to_actions"

window.ctaSuccessHandler = ctaSuccessHandler
window.ctaSuccessHandlerRecaptchaV3 = ctaSuccessHandlerRecaptchaV3
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
      .children('.form-container')
      .each(function (index) {
        $(this)
          .find(".position_field").val(index)
      });
  }

require("../../common")
