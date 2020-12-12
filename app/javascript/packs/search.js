function search(params) {
    const modelID = $("#search-model-id").val();
    const model = $("#search-model").val();
    $.ajax({
        url: "/item_search_form",
        type: "get",
        data: { search: params,
                id: modelID,
                model: model },
        async: false,
        success: function (data) {
            $("#search-results").append(data);
            $(".datepickers").datepicker({
              dateFormat: "yy-mm-dd"
            });
        },
        error: function () { alert("Search could not be completed."); }
    });
}

function initListeners() {
    if (document.querySelector("#search-submit") === null) { return; }

    $(document).on("click", "#search-submit", () => {
        $("#search-results").empty();
        const params = $("#search-params").val();
        if ( params !== "" ) { search(params); }
    });

    $(document).on("input", "#search-params", () => {
        $("#search-results").empty();
        const params = $("#search-params").val();
        if ( params !== "" && params.length > 2 ) {
          search(params);
        }
    });
}

$(() => {
  initListeners();
});
