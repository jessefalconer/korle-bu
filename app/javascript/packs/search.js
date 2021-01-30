function packingSearch(params) {
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
            initResultsDrawerListeners();
        },
        error: function () { alert("Search could not be completed."); }
    });
}

function reconcileSearch(params) {
    const compareID = $("#compare-id").val();
    $.ajax({
        url: "/reconcile_item_search",
        type: "get",
        data: { search: params,
                compare_id: compareID },
        async: false,
        success: function (data) {
            $("#search-results").append(data);
        },
        error: function () { alert("Search could not be completed."); }
    });
}

function initEstimateButton(el) {
  const id = $(el).data("item-id");
  const unit_weight = parseInt($(el).data("unit-weight"));

  $(`#estimate-item-${id}`).on("click", () => {
    const input_weight = parseInt($(`#weight-${id}`).val());
    var results = [];

    if (unit_weight === 0) {
      results.push("Error: this item has an unknown unit weight.");
    }
    if ( isNaN(input_weight) || input_weight === 0) {
      results.push("Error: please input a non-zero weight.");
    }
    if (results.length === 0) {
      let val = Math.ceil(input_weight/unit_weight);
      results.push(`Quantity estimated to be ${val} based on input weight.
                    \nUnit weight is recorded as ${unit_weight}grams.
                    \nYour inputs have not been changed.`);
    }

    alert(results.join("\n"));
  })
}

function initResultsDrawerListeners() {
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

    initEstimateButton(e.currentTarget);
  })
}

function initManageDrawerListeners() {
  if (document.querySelector(".manage-item-name") === null) { return; }

  $(".manage-item-name").on("click", e => {
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
}

function initReconcileSearchListeners() {
  if (document.querySelector("#reconcile-search-submit") === null) { return; }

  $(document).on("click", "#reconcile-search-submit", () => {
      $("#search-results").empty();
      const params = $("#search-params").val();
      if ( params !== "" ) { reconcileSearch(params); }
  });
}

$(() => {
  initPackingSearchListeners();
  initReconcileSearchListeners();
  initManageDrawerListeners();
});
