import { initManageDrawerListeners } from "./manage_item_search.js"

function indexSearch(params, path, initDrawers) {
    $.ajax({
        url: path,
        type: "get",
        data: { search: params },
        async: false,
        success: function (data) {
            $(".pagination").empty();
            $("#search-results").empty().append(data);
            if (initDrawers) initManageDrawerListeners();
        },
        error: function () { alert("Search could not be completed."); }
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
