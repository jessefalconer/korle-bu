import { initManageDrawerListeners } from "src/manage_item_search";
import { searchInto } from "src/search_request";

function indexSearch(params, path, initDrawers) {
  searchInto("#search-results", { url: path, data: { search: params } }, () => {
    $(".pagination").empty();
    if (initDrawers) initManageDrawerListeners();
  });
}

function bindSearchListeners(submitSelector, getPath) {
  const submit = () => {
    const params = $("#search-params").val();
    if (params !== "") indexSearch(params, getPath(), true);
  };

  $(document).on("click", submitSelector, submit);
  $(document).on("keyup", "#search-params", e => {
    if (e.key === "Enter") submit();
  });
}

function initIndexSearchListeners() {
  if (document.querySelector("#index-search-submit") === null) return;

  bindSearchListeners("#index-search-submit", () => $("#index-search-submit").data("path"));
}

function initPackedSearchListeners() {
  if (document.querySelector("#packed-search-submit") === null) return;

  bindSearchListeners("#packed-search-submit", () => "/packed_item_search");
}

$(() => {
  initIndexSearchListeners();
  initPackedSearchListeners();
});
