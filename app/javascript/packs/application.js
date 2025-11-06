// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from "@rails/ujs"

import "channels"
import "bootstrap"
import "chartkick/chart.js"
import ahoy from "ahoy.js";
import jQuery from 'jquery';

window.ahoy = ahoy;
global.$ = global.jQuery = jQuery;

Rails.start()

require("./trix")
require("./tribute")
require("./select2")
require("./common")
require("./turbo")

import "controllers"


import Revolvapp from '../../../public/revolvapp-2-3-10/revolvapp.js';
import '../../../public/revolvapp-2-3-10/css/revolvapp.min.css'
import '../../../public/revolvapp-2-3-10/css/revolvapp-frame.min.css'