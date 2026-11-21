function updateCheckCount() {
  const checkedCountRow = document.querySelectorAll("input.mass-action[type='checkbox']:checked").length;
  const checkedCountTable = document.querySelectorAll("input.mass-action-table[type='checkbox']:checked").length;
  const checkedCount = checkedCountRow + checkedCountTable;

  const counter = document.querySelector(".mass-action-count");
  if (!counter) return;

  counter.closest("button").disabled = checkedCount === 0;
  counter.textContent = checkedCount === 0 ? "" : `(${checkedCount})`;
}

// Highlights follow each checkbox's state (rather than toggling), so ticking many at
// once from the header can never leave a row's highlight out of step.
function initMassActions() {
  document.querySelectorAll(".mass-action").forEach(checkbox => {
    checkbox.addEventListener("change", e => {
      const on = e.target.checked;
      e.target.closest(".manage-item-name").classList.toggle("selected", on);
      e.target.closest(".inline-add-item").classList.toggle("selected", on);
      updateCheckCount();
    });
  });
}

// Row checkboxes a header select-all controls: those in its table, skipping rows the
// quick filter has hidden
function rowCheckboxes(table) {
  return [...table.querySelectorAll("tbody input.mass-action-table")]
    .filter(box => box.closest("tr").style.display !== "none");
}

// Header box: ticked when every (visible) row is, a dash when only some are
function syncSelectAll(table) {
  const header = table.querySelector("thead .mass-action-select-all");
  if (!header) return;

  const boxes = rowCheckboxes(table);
  const checked = boxes.filter(box => box.checked).length;
  header.checked = boxes.length > 0 && checked === boxes.length;
  header.indeterminate = checked > 0 && checked < boxes.length;
}

function setRowSelected(checkbox) {
  const row = checkbox.closest("tr");
  row.classList.toggle("selected", checkbox.checked);
  for (const cell of row.children) cell.classList.toggle("selected", checkbox.checked);
}

function initMassActionsTable() {
  document.querySelectorAll(".mass-action-table").forEach(checkbox => {
    checkbox.addEventListener("change", e => {
      setRowSelected(e.target);
      syncSelectAll(e.target.closest("table"));
      updateCheckCount();
    });
  });

  document.querySelectorAll(".mass-action-select-all").forEach(header => {
    header.addEventListener("change", () => {
      const table = header.closest("table");
      rowCheckboxes(table).forEach(box => {
        box.checked = header.checked;
        setRowSelected(box);
      });
      syncSelectAll(table);
      updateCheckCount();
    });
  });

  // The quick filter shows and hides rows; keep the header's state about what is visible
  document.addEventListener("input", e => {
    if (!e.target.matches(".table-quick-filter")) return;
    document.querySelectorAll("table").forEach(syncSelectAll);
  });
}

// The whole checkbox cell is the hit area, not just the small box
document.addEventListener("click", e => {
  const cell = e.target.closest(".mass-action-cell");
  if (!cell || e.target.matches("input")) return;

  const box = cell.querySelector("input[type='checkbox']");
  if (box && !box.disabled) box.click();
});

$(() => {
  initMassActions();
  initMassActionsTable();
});
