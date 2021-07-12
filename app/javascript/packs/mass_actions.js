function updateCheckCount() {
  var checkedCountRow = document.querySelectorAll("input.mass-action[type='checkbox']:checked").length;
  var checkedCountTable = document.querySelectorAll("input.mass-action-table[type='checkbox']:checked").length;
  var checkedCount = checkedCountRow + checkedCountTable

  const button = document.querySelector(".mass-action-count");
  var text = "";
  if (checkedCount === 0) {
    text = "";
    button.closest("button").disabled = true;
  } else {
    text = `(${checkedCount})`;
    button.closest("button").disabled = false;
  }
  button.textContent = text;
}

function initMassActions() {
  const checkboxes = document.querySelectorAll(".mass-action");
  if (!checkboxes) return;

  checkboxes.forEach(checkbox => {
    checkbox.addEventListener("change", e => {
      e.target.closest(".manage-item-name").classList.toggle("selected");
      e.target.closest(".inline-add-item").classList.toggle("selected");
      updateCheckCount();
    });
  })
}

function initMassActionsTable() {
  const checkboxes = document.querySelectorAll(".mass-action-table");
  if (!checkboxes) return;

  checkboxes.forEach(checkbox => {
    checkbox.addEventListener("change", e => {
      tdEls = e.target.parentNode.parentNode.children
      for (let tdEl of tdEls) {
        tdEl.classList.toggle("selected");
      };

      e.target.closest("tr").classList.toggle("selected");
      updateCheckCount();
    });
  })
}

$(() => {
  initMassActions();
  initMassActionsTable();
});
