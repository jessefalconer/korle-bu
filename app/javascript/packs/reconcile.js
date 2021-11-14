function reconcileSearch(params) {
    const compareId = $("#compare-id").val();
    const similarIds = $("#compare-id").data("similar-ids");
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

function updateCheckCount() {
  var checkedCount = document.querySelectorAll('input[type="checkbox"]:checked').length;
  const buttons = document.querySelectorAll(".submit-count");

  for (var i = 0; i < buttons.length; i++) {
      const textValue = buttons[i].classList.contains("mass-reassign") ? "Reassign" : "Confirm Reconcile";
      var text = checkedCount === 0 ? `\t ${textValue}` : `\t${textValue} (${checkedCount})`;
      buttons[i].getElementsByTagName("span")[0].textContent = text;
  }
}

function initReconcileCheckBoxListeners() {
  if (!document.querySelectorAll(".submit-count")[0]) return;
  const checkboxes = document.querySelectorAll("input[type=checkbox]");
  if (!checkboxes) return;

  checkboxes.forEach(checkbox => {
    checkbox.addEventListener("change", e => {
      tdEls = e.target.parentNode.parentNode.children
      for (let tdEl of tdEls) {
        tdEl.classList.toggle("selected");
      };

      e.target.closest("tr").classList.toggle("selected");
      updateCheckCount();
    });
  })
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

$(() => {
  initReconcileSearchListeners();
  initReconcileCheckBoxListeners();
});
