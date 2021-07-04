
function reconcileSearch(params) {
    const compareId = $("#compare-id").val();
    const similarIds = $("#compare-id").data("similar-ids")
    $.ajax({
        url: "/reconcile_item_search",
        type: "get",
        data: { search: params,
                compare_id: compareId,
                similar_ids: similarIds },
        async: false,
        success: function (data) {
            $("#search-results").empty();
            $("#search-results").append(data);
            initCheckBoxListeners();
            updateCheckCount();
        },
        error: function () { alert("Search could not be completed."); }
    });
}

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

function updateCheckCount() {
  var checkedCount = document.querySelectorAll('input[type="checkbox"]:checked').length;
  const buttons = document.querySelectorAll(".submit-count")

  for (var i = 0; i < buttons.length; i++) {
      const textValue = buttons[i].classList.contains("mass-reassign") ? "Reassign" : "Confirm Reconcile"
      var text = checkedCount === 0 ? `\t ${textValue}` : `\t${textValue} (${checkedCount})`
      buttons[i].getElementsByTagName("span")[0].textContent = text
  }
}

function initCheckBoxListeners() {
  if (!document.querySelectorAll(".submit-count")) return;
  const checkboxes = document.querySelectorAll("input[type=checkbox]");

  for (var i = 0; i < checkboxes.length; i++) {
      checkboxes[i].addEventListener("change", updateCheckCount, false);
  }
}

function initReconcileSearchListeners() {
  if (document.querySelector("#reconcile-search-submit") === null) { return; }

  updateCheckCount();

  $(document).on('keyup keypress', 'form input[type="text"]', function(e) {
    if(e.which == 13) {
      e.preventDefault();
      return false;
    }
  });

  $(document).on("click", "#reconcile-search-submit", () => {
      $("#search-results").empty();
      const params = $("#search-params").val();
      if (params !== "") reconcileSearch(params);
  });

  $(document).on("keyup", "#search-params", e => {
      if (e.key === "Enter") {
        const params = $("#search-params").val();
        if ( params !== "" ) reconcileSearch(params);
      }
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
  initReconcileSearchListeners();
  initIndexSearchListeners();
  initCheckBoxListeners();
});
