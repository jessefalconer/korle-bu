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

      $(`#stage-flag-${id}`).val(false);

      if (selected != "Staging") {
        $(`#${selected.toLowerCase()}-assignment-form-${id}`).removeClass("hidden").hide().fadeIn();
      }
    });
  });
}

$(() => {
  if ($(".staging-assignments")[0] !== undefined) initAssignmentListeners();
});
