// Remembers which dashboard cards someone has collapsed. Kept in this browser
// only (it's a viewing preference), and the dashboard works the same without it.
const STORAGE_KEY = "dashboard:collapsed";

function readCollapsed() {
  try {
    return new Set(JSON.parse(localStorage.getItem(STORAGE_KEY)) || []);
  } catch (_e) {
    return new Set(); // private window, blocked storage or bad data
  }
}

function writeCollapsed(ids) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify([...ids]));
  } catch (_e) {
    // Not saved; nothing else depends on it
  }
}

$(() => {
  if (document.querySelector(".dashboard-toolbar") === null) return;

  const collapsed = readCollapsed();
  // Runs before application.js syncs the header chevrons, so they match
  collapsed.forEach(id => document.getElementById(id)?.classList.remove("show"));

  $(document).on("hidden.bs.collapse shown.bs.collapse", ".main-content .card > .collapse", e => {
    if (e.target !== e.currentTarget || !e.currentTarget.id) return;

    if (e.type === "hidden") collapsed.add(e.currentTarget.id);
    else collapsed.delete(e.currentTarget.id);
    writeCollapsed(collapsed);
  });
});
