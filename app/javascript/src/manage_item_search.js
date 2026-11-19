import { searchInto } from "src/search_request";

function packingSearch(params) {
  searchInto("#search-results", {
    url: "/item_search_form",
    data: {
      search: params,
      id: $("#search-model-id").val(),
      model: $("#search-model").val(),
      status: $("#status").val()
    }
  }, () => {
    $("#search-results .datepickers").datepicker({ dateFormat: "yy-mm-dd" });
    initResultsDrawerListeners(params);
  });
}

const DRAWER_MS = 200;

// Opens or closes the form under a list row. stop() drops queued animations, so
// rapid taps reverse the slide smoothly instead of stacking up.
function toggleDrawer(header) {
  const $header = $(header);
  const drawer = $header.next();
  const opening = !$header.hasClass("open");

  $header.toggleClass("open", opening).attr("aria-expanded", opening);

  // An interrupted slide leaves inline sizes behind; clear them so the drawer can
  // grow with its contents afterwards
  const reset = { height: "", marginTop: "", marginBottom: "", paddingTop: "", paddingBottom: "", overflow: "", opacity: "" };

  if (opening) {
    // .hidden is display:none !important, so swap it for an inline display:none to slide from
    if (drawer.hasClass("hidden")) drawer.hide().removeClass("hidden");
    drawer.stop(true)
      .css("opacity", drawer.is(":visible") ? drawer.css("opacity") : 0)
      .animate({ opacity: 1 }, { duration: DRAWER_MS, queue: false })
      .slideDown(DRAWER_MS, () => drawer.css(reset));
  } else {
    drawer.stop(true)
      .animate({ opacity: 0 }, { duration: DRAWER_MS, queue: false })
      .slideUp(DRAWER_MS, () => drawer.addClass("hidden").css(reset).css("display", ""));
  }
}

// Bold each search word (2+ chars) inside the result names, preserving the original casing
function highlightMatches(elements, params) {
  const words = params
    .split(" ")
    .filter(word => word.length > 1)
    .map(word => word.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"));
  if (words.length === 0) return;

  const pattern = new RegExp(`(${words.join("|")})`, "gi");

  elements.forEach(el => {
    // split() with a capture group alternates [text, match, text, match, ...]
    const parts = el.textContent.split(pattern).map((part, i) => {
      if (i % 2 === 0) return document.createTextNode(part);

      const strong = document.createElement("strong");
      strong.textContent = part;
      return strong;
    });
    el.replaceChildren(...parts);
  });
}

function initResultsDrawerListeners(params) {
  highlightMatches(document.querySelectorAll(".results-item-name-value"), params);

  // Namespaced so a re-render never binds a second handler (which would open then instantly close)
  $(".results-item-name").off("click.drawer").on("click.drawer", e => toggleDrawer(e.currentTarget));
}

export function initManageDrawerListeners() {
  if (document.querySelector(".manage-item-name") === null) { return; }

  $(".manage-item-name").off("click.drawer").on("click.drawer", e => {
    // Do not toggle drawer if input selected
    if (e.target.nodeName === "INPUT") return;

    toggleDrawer(e.currentTarget);
  })
}

function initPackingSearchListeners() {
  if (document.querySelector("#packing-search-submit") === null) { return; }

  const searchDelayInterval = 300;
  const minimumChars = 3;
  let typingTimer;

  const searchNow = () => {
    clearTimeout(typingTimer);
    const params = $("#search-params").val();
    if (params !== "") packingSearch(params);
  };

  $(document).on("input", "#search-params", () => {
    clearTimeout(typingTimer);
    const params = $("#search-params").val();

    if (params.length >= minimumChars) {
      typingTimer = setTimeout(searchNow, searchDelayInterval);
    } else if (params === "") {
      $("#search-results").empty();
    }
  });

  $(document).on("click", "#packing-search-submit", searchNow);
  $(document).on("keyup", "#search-params", e => {
    if (e.key === "Enter") searchNow();
  });
}

$(() => {
  initPackingSearchListeners();
  initManageDrawerListeners();
});
