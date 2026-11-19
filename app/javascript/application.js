// Entry point, loaded as a module through the importmap (config/importmap.rb).
//
// jQuery, Bootstrap 3 and jQuery UI are loaded as plain scripts by the layout
// before this module runs, so the global $ / jQuery are already set up here.

import Rails from "@rails/ujs";
Rails.start();

import "src/errors";
import "src/manage_item_search";
import "src/item_search";
import "src/quick_filter";
import "src/reassign";
import "src/reconcile";
import "src/mass_actions";
import "chartkick";
import "Chart.bundle";

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
