function initAssignmentListeners() {
  $(document).on("change", `#item-assignment`, () => {
    const selected = $(`#item-assignment option:selected`).text();

    $(`#box-assignment-form,
        #pallet-assignment-form,
        #container-assignment-form`).addClass("hidden");

    $(`#box-assignment-input option:selected,
        #pallet-assignment-input option:selected,
        #container-assignment-input option:selected`).prop("disabled", true);

    if (selected != "Staging" && selected != "Warehouse") {
      $("#status-flag").val(null);
      $(`#${selected.toLowerCase()}-assignment-form`).removeClass("hidden").hide().fadeIn();
      $(`#${selected.toLowerCase()}-assignment-input option:selected`).prop("disabled", false);
    } else if (selected === "Staging" || selected === "Warehouse") {
      $("#status-flag").val(selected);
    } else {
      $("#status-flag").val(null);
    }
  });
}

$(() => {
  if ($(".item-assignments")[0] !== undefined) initAssignmentListeners();
});
