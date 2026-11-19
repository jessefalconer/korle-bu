function updateCheckCount() {
  const checkedCountRow = document.querySelectorAll("input.mass-action[type='checkbox']:checked").length;
  const checkedCountTable = document.querySelectorAll("input.mass-action-table[type='checkbox']:checked").length;
  const checkedCount = checkedCountRow + checkedCountTable;

  const counter = document.querySelector(".mass-action-count");
  counter.closest("button").disabled = checkedCount === 0;
  counter.textContent = checkedCount === 0 ? "" : `(${checkedCount})`;
}

function initMassActions() {
  const checkboxes = document.querySelectorAll(".mass-action");

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

  checkboxes.forEach(checkbox => {
    checkbox.addEventListener("change", e => {
      for (const tdEl of e.target.closest("tr").children) {
        tdEl.classList.toggle("selected");
      }

      e.target.closest("tr").classList.toggle("selected");
      updateCheckCount();
    });
  })
}

$(() => {
  initMassActions();
  initMassActionsTable();
});
