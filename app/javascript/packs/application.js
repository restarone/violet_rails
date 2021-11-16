// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"

import "channels"
import "bootstrap"
import "chartkick/chart.js"

import ahoy from "ahoy.js";
import ctaSuccessHandler from "./website/call_to_actions"
window.ahoy = ahoy;
window.ctaSuccessHandler = ctaSuccessHandler

Rails.start()
Turbolinks.start()


require("jquery")
require("./trix")
require("./select2")

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
