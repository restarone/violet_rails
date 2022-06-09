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
import ctaSuccessHandler, {ctaSuccessHandlerRecaptchaV3} from "./website/call_to_actions"
window.ahoy = ahoy;
window.ctaSuccessHandler = ctaSuccessHandler
window.ctaSuccessHandlerRecaptchaV3 = ctaSuccessHandlerRecaptchaV3

Rails.start()
Turbolinks.start()


require("jquery")
require("./trix")
require("./select2")
require("./common")