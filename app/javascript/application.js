// Entry point, loaded as a module through the importmap (config/importmap.rb).
//
// jQuery, Bootstrap 5 and jQuery UI are loaded as plain scripts by the layout before
// this module runs, so the global $ / jQuery are already set up here. Bootstrap 5 sees
// jQuery and still fires its events through it (e.g. "show.bs.collapse").

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

// Bootstrap sets `.collapsed` on a toggle only once it has been clicked, so set it from
// each target's real state on load; the CSS chevrons rely on it. (Bootstrap 5 keeps it in
// sync from then on, including toggles that target a class, like ".dashboard-menu".)
function syncCollapseToggles() {
  $("[data-bs-toggle='collapse']").each((_i, el) => {
    const target = $(el).attr("data-bs-target") || $(el).attr("href");
    if (!target || target === "#" || el.classList.contains("navbar-toggler")) return;

    let $target;
    try { $target = $(target).first(); } catch (_e) { return; } // not a valid selector
    if ($target.length) $(el).toggleClass("collapsed", !$target.hasClass("show"));
  });
}

$(() => {
  const uls = $(".sidebar-nav > ul > *").clone();
  uls.addClass("d-sm-none");
  $("#main-menu").append(uls);

  $(".datepickers").datepicker({ dateFormat: "yy-mm-dd" });
  syncCollapseToggles();
});
