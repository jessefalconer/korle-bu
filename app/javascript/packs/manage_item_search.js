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
            initResultsDrawerListeners();
        },
        error: function () { alert("Search could not be completed."); }
    });
}

function initEstimateButton(el) {
  const id = $(el).data("item-id");
  const unitWeight = parseInt($(el).data("unit-weight"));

  $(`#estimate-item-${id}`).on("click", () => {
    var inputWeight = parseInt($(`#weight-${id}`).val());
    var inputQuantity = parseInt($(`#quantity-${id}`).val());
    var results = [];

    if (unitWeight === 0) {
      results.push("Error: this item has an unknown unit weight. Weigh the individual item and update its information.");
    } else {
      if ( isNaN(inputWeight) || inputWeight === 0 ) {
        results.push("Input a non-zero weight value to get a quantity estimate.");
      } else {
        let qVal = Math.ceil(inputWeight/unitWeight);
        results.push(`Quantity estimated to be ${qVal} based on input weight.`);
      }
      if ( isNaN(inputQuantity) || inputQuantity === 0 ) {
        results.push("Input a non-zero quantity value to get a weight estimate.");
      } else {
        let wVal = Math.ceil(inputQuantity*unitWeight);
        results.push(`Weight estimated to be ${wVal} kilograms based on input quantity.`);
      }
      results.push(`<br>Unit weight is currently set at ${unitWeight} kilograms.<br>Your inputs have not been changed.`)
    }

    $("#estimateModalBody").html(results.join("<br>"))
    $("#estimateModal").modal();
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
