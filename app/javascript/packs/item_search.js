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

function initIndexSearchListeners() {
  if (document.querySelector("#index-search-submit") === null) { return; }

  const initDrawers = true;
  $(document).on("click", "#index-search-submit", () => {
      const params = $("#search-params").val();
      const path = $("#index-search-submit").data("path");
      if (params !== "") indexSearch(params, path, initDrawers);
  });

  $(document).on("keyup", "#search-params", e => {
      if (e.key === "Enter") {
        const params = $("#search-params").val();
        const path = $("#index-search-submit").data("path");
        if (params !== "") indexSearch(params, path, initDrawers);
      }
  });
}

function initPackedSearchListeners() {
  if (document.querySelector("#packed-search-submit") === null) { return; }

  const path = "/packed_item_search";
  const initDrawers = true;
  $(document).on("click", "#packed-search-submit", () => {
      const params = $("#search-params").val();
      if (params !== "") indexSearch(params, path, initDrawers);
  });

  $(document).on("keyup", "#search-params", e => {
      if (e.key === "Enter") {
        const params = $("#search-params").val();
        if (params !== "") indexSearch(params, path, initDrawers);
      }
  });
}

$(() => {
  initIndexSearchListeners();
  initPackedSearchListeners();
});
