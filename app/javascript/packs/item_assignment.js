function toggleAssignments(id) {
  const selected = $(`#item-assignment-${id} option:selected`).text();

  $(`#box-assignment-form-${id},
      #pallet-assignment-form-${id},
      #container-assignment-form-${id}`).addClass("hidden");

  $(`#box-assignment-input-${id} option:selected,
      #pallet-assignment-input-${id} option:selected,
      #container-assignment-input-${id} option:selected`).prop("selected", false);

  if (selected != "Staging" && selected != "Warehouse") {
    $(`#status-flag-${id}`).val("Packed");
    $(`#${selected.toLowerCase()}-assignment-form-${id}`).removeClass("hidden").hide().fadeIn();
    const assignment = [`#box-assignment-input-${id}`, `#pallet-assignment-input-${id}`, `#container-assignment-input-${id}`];
    $(assignment.join(", ")).prop("disabled", false);

    var disabled = assignment.filter(function(e) { return e !== `#${selected.toLowerCase()}-assignment-input-${id}` });

    $(disabled.join(", ")).prop("disabled", true)
  } else if (selected === "Staging" || selected === "Warehouse") {
    $(`#status-flag-${id}`).val(selected);
    $(`#box-assignment-input-${id},
      #pallet-assignment-input-${id},
      #container-assignment-input-${id}`).prop("disabled", true);
  } else {
    $(`#status-flag-${id}`).val("Packed");
    $(`#box-assignment-input-${id},
      #pallet-assignment-input-${id},
      #container-assignment-input-${id}`).prop("disabled", false);
  }
}

function initAssignmentListeners() {
  const selectEls = document.querySelectorAll(".item-assignments");

  Reflect.apply(Array, undefined, selectEls).forEach(selectEl => {
    const id = selectEl.dataset.id;

    toggleAssignments(id);
    $(document).on("change", `#item-assignment-${id}`, () => {
      toggleAssignments(id);
    });
  });
}

$(() => {
  if ($(".item-assignments")[0] !== undefined) initAssignmentListeners();
});
