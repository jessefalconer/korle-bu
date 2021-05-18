function initAssignmentListeners() {
  const stagingSelectEls = document.querySelectorAll(".staging-assignments");

  Reflect.apply(Array, undefined, stagingSelectEls).forEach(selectEl => {
    const id = selectEl.dataset.id;

    $(document).on("change", `#staging-assignment-${id}`, () => {
      const selected = $(`#staging-assignment-${id} option:selected`).text();

      $(`#box-assignment-form-${id},
         #pallet-assignment-form-${id},
         #container-assignment-form-${id}`).addClass("hidden");

      $(`#box-assignment-input-${id} option:selected,
         #pallet-assignment-input-${id} option:selected,
         #container-assignment-input-${id} option:selected`).prop("selected", false);

      if (selected != "Staging" && selected != "Warehouse") {
        $(`#status-flag-${id}`).val(null);
        $(`#${selected.toLowerCase()}-assignment-form-${id}`).removeClass("hidden").hide().fadeIn();
      } else if (selected === "Staging" || selected === "Warehouse") {
        $(`#status-flag-${id}`).val(selected);
      } else {
        $(`#status-flag-${id}`).val(null);
      }
    });
  });
}

$(() => {
  if ($(".staging-assignments")[0] !== undefined) initAssignmentListeners();
});
