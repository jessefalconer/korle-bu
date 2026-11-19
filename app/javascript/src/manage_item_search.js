function packingSearch(params) {
    const modelID = $("#search-model-id").val();
    const model = $("#search-model").val();
    const status = $("#status").val();
    $.ajax({
        url: "/item_search_form",
        type: "get",
        data: { search: params,
                id: modelID,
                model: model,
                status: status },
        async: false,
        success: function (data) {
            $("#search-results").append(data);
            $(".datepickers").datepicker({
              dateFormat: "yy-mm-dd"
            });
            initResultsDrawerListeners(params);
        },
        error: function () { alert("Search could not be completed."); }
    });
}

function toggleDrawer(header) {
  const $header = $(header);
  const icon = $header.find("i");
  const sibling = $header.next();

  if (sibling.hasClass("hidden")) {
    sibling.removeClass("hidden").hide().slideDown("fast");
    icon.removeClass("fa-ellipsis-v").addClass("fa-times");
    $header.addClass("open");
  } else {
    sibling.slideUp("fast", () => {
      sibling.addClass("hidden").slideDown("fast");
      icon.removeClass("fa-times").addClass("fa-ellipsis-v");
      $header.removeClass("open");
    });
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

  $(".results-item-name").on("click", e => toggleDrawer(e.currentTarget));
}

export function initManageDrawerListeners() {
  if (document.querySelector(".manage-item-name") === null) { return; }

  $(".manage-item-name").on("click", e => {
    // Do not toggle drawer if input selected
    if (e.target.nodeName === "INPUT") return;

    toggleDrawer(e.currentTarget);
  })
}

function initPackingSearchListeners() {
  if (document.querySelector("#packing-search-submit") === null) { return; }

  var typingTimer;
  var searchDelayInterval = 300;
  var params;
  var minimumChars = 3;

  $(document).on("input", "#search-params", function(){
      clearTimeout(typingTimer);
      params = $("#search-params").val();
      if ( params !== "" && params.length >= minimumChars ) {
          typingTimer = setTimeout(typingComplete, searchDelayInterval);
      } else if ( params === "" ) {
        $("#search-results").empty();
      }
  });

  function typingComplete () {
      $("#search-results").empty();
      packingSearch(params);
  }

  $(document).on("click", "#packing-search-submit", () => {
      $("#search-results").empty();
      const params = $("#search-params").val();
      if ( params !== "" ) { packingSearch(params); }
  });

  $(document).on("keyup", "#search-params", e => {
      if (e.key === "Enter") {
        const params = $("#search-params").val();
        if ( params !== "" ) { packingSearch(params); }
      }
  });
}

$(() => {
  initPackingSearchListeners();
  initManageDrawerListeners();
});
