// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

// Share webpack's jQuery with the CDN-loaded jQuery UI plugin (see application layout)
window.$ = window.jQuery = $;

require("@rails/ujs").start()

import "../src/errors";
import "bootstrap/dist/js/bootstrap";
import "../src/manage_item_search";
import "../src/item_search";
import "../src/quick_filter";
import "../src/reassign";
import "../src/reconcile";
import "../src/mass_actions";
import "chartkick/chart.js"

// Respect the OS "reduce motion" setting for jQuery animations too
$.fx.off = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

// Bootstrap only flips `.collapsed` on a toggle when it is clicked, so set it from each
// target's real state on load; the CSS chevrons rely on it
function syncCollapseToggles() {
  $("[data-toggle='collapse']").each((_i, el) => {
    const target = $(el).attr("data-target") || $(el).attr("href");
    if (!target || target === "#" || el.closest(".navbar-header")) return;

    let $target;
    try { $target = $(target).first(); } catch (_e) { return; } // not a valid selector
    if ($target.length) $(el).toggleClass("collapsed", !$target.hasClass("in"));
  });
}

$(() => {
  const uls = $(".sidebar-nav > ul > *").clone();
  uls.addClass("visible-xs");
  $("#main-menu").append(uls);

  $(".datepickers").datepicker({ dateFormat: "yy-mm-dd" });
  syncCollapseToggles();
});
