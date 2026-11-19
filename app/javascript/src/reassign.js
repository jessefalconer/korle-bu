function initAssignmentListeners() {
  const quickNav = document.querySelector("ul.nav.nav-tabs.quick-add")

  if (quickNav != null) {
    quickNav.firstElementChild.classList.add("active");
    document.querySelector(".tab-content.quick-add").children[1].classList.add("active", "in");
  }


  $(`#box-assignment-input option:selected,
      #pallet-assignment-input option:selected,
      #container-assignment-input option:selected`).prop("disabled", true);

  $(document).on("change", `#item-assignment`, () => {
    const selected = $(`#item-assignment option:selected`).text();

    $(`#current-location-message,
        #warehouse-message,
        #staging-message,
        #box-assignment-form,
        #pallet-assignment-form,
        #container-assignment-form`).addClass("hidden");

    $(`#box-assignment-input option:selected,
        #pallet-assignment-input option:selected,
        #container-assignment-input option:selected`).prop("disabled", true);

    if (selected === "Box" || selected === "Pallet" || selected === "Container") {
      $("#status-flag").val(null);
      $("#current-location").val(false);
      $(`#${selected.toLowerCase()}-assignment-form`).removeClass("hidden").hide().fadeIn();
      $(`#${selected.toLowerCase()}-assignment-input option:selected`).prop("disabled", false);
    } else if (selected === "Staging" || selected === "Warehouse") {
      $(`#${selected.toLowerCase()}-message`).removeClass("hidden").hide().fadeIn();
      // Ugly way to match validated statuses, yuck
      $("#status-flag").val(selected === "Staging" ? "Staged" : "Warehoused");
      $("#current-location").val(false);
    } else if (selected === "Current Location") {
      $("#current-location-message").removeClass("hidden").hide().fadeIn();
      $("#status-flag").val(null);
      $("#current-location").val(true);
    } else {
      $("#status-flag").val(null);
      $("#current-location").val(false);
    }
  });
}

$(() => {
  if ($(".record-assignments")[0] !== undefined) initAssignmentListeners();
});
