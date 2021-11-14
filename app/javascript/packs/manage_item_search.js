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

function initResultsDrawerListeners(params) {
  const resultsEls = document.querySelectorAll(".results-item-name-value");
  const paramsCompare = params.split(" ");

  resultsEls.forEach(el => {
    for (const word of paramsCompare) {
      if (word.length === 1) break;
      const elText = el.innerHTML.toLowerCase();
      if (elText.indexOf(word.toLowerCase()) >= 0) {
        el.innerHTML = elText.replace(word, `<strong>${word}</strong>`);
      }
    }
  })

  $(".results-item-name").on("click", e => {
    const icon = $(e.currentTarget).find("i");
    const sibling = $(e.currentTarget).next();

    if (sibling.hasClass("hidden")) {
      sibling.removeClass("hidden").hide().slideDown("fast");
      icon.removeClass("fa-ellipsis-v");
      icon.addClass("fa-times");
      $(e.currentTarget).addClass("open");
    } else {
      sibling.slideUp("fast", function() {
        sibling.addClass("hidden").slideDown("fast");
        icon.removeClass("fa-times");
        icon.addClass("fa-ellipsis-v");
        $(e.currentTarget).removeClass("open");
      });
    }
  })
}

export function initManageDrawerListeners() {
  if (document.querySelector(".manage-item-name") === null) { return; }

  $(".manage-item-name").on("click", e => {
    // Do not toggle drawer if input selected
    if (e.target.nodeName === "INPUT") return;

    const icon = $(e.currentTarget).find("i");
    const sibling = $(e.currentTarget).next();

    if (sibling.hasClass("hidden")) {
      sibling.removeClass("hidden").hide().slideDown("fast");
      icon.removeClass("fa-ellipsis-v");
      icon.addClass("fa-times");
      $(e.currentTarget).addClass("open");
    } else {
      sibling.slideUp("fast", function() {
        sibling.addClass("hidden").slideDown("fast");
        icon.removeClass("fa-times");
        icon.addClass("fa-ellipsis-v");
        $(e.currentTarget).removeClass("open");
      });
    }
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
