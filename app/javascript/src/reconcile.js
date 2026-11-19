import { searchInto } from "src/search_request";

function reconcileSearch(params) {
  searchInto("#search-results", {
    url: "/reconcile_item_search",
    data: {
      search: params,
      compare_id: $("#compare-id").val(),
      similar_ids: $("#compare-id").data("similar-ids")
    }
  }, () => {
    initReconcileCheckBoxListeners(document.getElementById("search-results"));
    updateCheckCount();
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

// `root` limits binding to freshly loaded search results, so existing checkboxes
// are not bound twice (a double toggle would cancel itself out)
function initReconcileCheckBoxListeners(root = document) {
  if (!document.querySelectorAll(".submit-count")[0]) return;
  const checkboxes = root.querySelectorAll("input[type=checkbox]");

  checkboxes.forEach(checkbox => {
    checkbox.addEventListener("change", e => {
      for (const tdEl of e.target.closest("tr").children) {
        tdEl.classList.toggle("selected");
      }

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
