import { searchInto } from "src/search_request";

// The term the current results are for, so a second Enter opens the first result
let lastSearch = null;

function packingSearch(params) {
  lastSearch = params;
  searchInto("#search-results", {
    url: "/item_search_form",
    data: {
      search: params,
      id: $("#search-model-id").val(),
      model: $("#search-model").val(),
      status: $("#status").val()
    }
  }, () => {
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
  highlightMatches(document.querySelectorAll("#search-results .results-item-name-value"), params);
}

// ---------------------------------------------------------------- Keyboard flow
// Search, Enter, Enter (opens the first result), quantity, Enter (adds it).
// Result rows are buttons: Enter/Space opens one, arrow keys move between them.

function focusQuantity(header) {
  const quantity = $(header).next().find(".js-quantity")[0];
  if (!quantity) return;

  quantity.focus();
  quantity.select();
}

function openResult(header) {
  if (!$(header).hasClass("open")) toggleDrawer(header);
  focusQuantity(header);
}

// Rows of whichever list is showing: search results, or recent items before a search
function visibleResultRows() {
  return $(".results-item-name:visible").toArray();
}

function moveFocus(from, step) {
  const rows = visibleResultRows();
  const index = rows.indexOf(from) + step;
  if (index < 0) $("#search-params").trigger("focus");
  else if (rows[index]) rows[index].focus();
}

function initResultKeyboard() {
  // Delegated once, so rows added by later searches work too
  $(document).on("click", ".results-item-name", e => toggleDrawer(e.currentTarget));

  $(document).on("keydown", ".results-item-name", e => {
    const row = e.currentTarget;
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault();
      if ($(row).hasClass("open")) toggleDrawer(row);
      else openResult(row);
    } else if (e.key === "ArrowDown" || e.key === "ArrowUp") {
      e.preventDefault();
      moveFocus(row, e.key === "ArrowDown" ? 1 : -1);
    }
  });
}

// ---------------------------------------------------------------- Weight from unit weight
// Each result form carries its item's unit weight. Weight follows quantity × unit
// weight until someone types a weight of their own.
function initWeightFill() {
  $(document).on("input", "form[data-unit-weight] .js-quantity", e => {
    const form = e.target.form;
    const weight = form.querySelector(".js-weight");
    if (!weight || weight.dataset.edited) return;

    const quantity = parseFloat(e.target.value);
    const unitWeight = parseFloat(form.dataset.unitWeight);
    weight.value = quantity > 0 ? Number((quantity * unitWeight).toFixed(3)) : "";
  });

  $(document).on("input", ".js-weight", e => { e.target.dataset.edited = "true"; });
}

// Recent items stand in for search results until something is typed
function toggleRecentItems(searching) {
  $("#recent-items").toggleClass("hidden", searching);
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
    toggleRecentItems(params !== "");

    if (params.length >= minimumChars) {
      typingTimer = setTimeout(searchNow, searchDelayInterval);
    } else if (params === "") {
      lastSearch = null;
      $("#search-results").empty();
    }
  });

  $(document).on("click", "#packing-search-submit", searchNow);

  $(document).on("keydown", "#search-params", e => {
    const params = $("#search-params").val();
    const firstResult = $("#search-results .results-item-name")[0];

    if (e.key === "Enter") {
      e.preventDefault();
      // Results already showing for this term: Enter opens the first one
      if (params !== "" && params === lastSearch && firstResult) openResult(firstResult);
      else searchNow();
    } else if (e.key === "ArrowDown") {
      const first = visibleResultRows()[0];
      if (first) { e.preventDefault(); first.focus(); }
    } else if (e.key === "Escape" && params !== "") {
      $("#search-params").val("").trigger("input");
    }
  });

  initResultKeyboard();
  initWeightFill();
}

$(() => {
  initPackingSearchListeners();
  initManageDrawerListeners();
});
