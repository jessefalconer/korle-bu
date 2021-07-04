// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require("@rails/ujs").start()
require("@rails/activestorage").start()
require("channels")

import "../packs/errors";
import "../packs/bootstrap";
import "../packs/manage_item_search";
import "../packs/item_search";
import "../packs/quick_filter";
import "../packs/reassign";
import "../packs/reconcile";
import "../packs/mass_actions";
import "chartkick/chart.js"

$(function () {
  var uls = $('.sidebar-nav > ul > *').clone();
  uls.addClass('visible-xs');
  $('#main-menu').append(uls.clone());
});

$(document).ready(function () {
    $(".datepickers").datepicker({
      dateFormat: "yy-mm-dd"
    });
});
