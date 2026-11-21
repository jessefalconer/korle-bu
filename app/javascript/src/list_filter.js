// The list filter's "Created by" dropdown is a <details>: close it on a click
// outside it or on Escape, like a select would.
document.addEventListener("click", e => {
  document.querySelectorAll(".filter-dropdown[open]").forEach(dropdown => {
    if (!dropdown.contains(e.target)) dropdown.removeAttribute("open");
  });
});

document.addEventListener("keydown", e => {
  if (e.key !== "Escape") return;

  const dropdown = e.target.closest?.(".filter-dropdown[open]");
  if (!dropdown) return;
  dropdown.removeAttribute("open");
  dropdown.querySelector("summary").focus();
});
