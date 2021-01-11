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
            initResultsDrawerListeners();
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
  if (document.querySelector(".manage-item-name") === null) { return; }

  initManageDrawerListeners();
});
