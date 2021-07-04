function indexSearch(params, path) {
    $.ajax({
        url: path,
        type: "get",
        data: { search: params },
        async: false,
        success: function (data) {
            $(".pagination").empty();
            $("#search-results").empty().append(data);
        },
        error: function () { alert("Search could not be completed."); }
    });
}

function initIndexSearchListeners() {
  if (document.querySelector("#index-search-submit") === null) { return; }

  $(document).on("click", "#index-search-submit", () => {
      const params = $("#search-params").val();
      const path = $("#index-search-submit").data("path");
      if (params !== "") indexSearch(params, path);
  });

  $(document).on("keyup", "#search-params", e => {
      if (e.key === "Enter") {
        const params = $("#search-params").val();
        const path = $("#index-search-submit").data("path");
        if (params !== "") indexSearch(params, path);
      }
  });
}

$(() => {
  initIndexSearchListeners();
});
