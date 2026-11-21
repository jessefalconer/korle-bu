// On phones the tab bar is one row that scrolls sideways. Mark which ends have more
// tabs out of view (.more-start / .more-end) so the CSS can show an edge fade and
// chevron there, and bring a tapped tab fully into view.
function updateHints(bar) {
  const max = bar.scrollWidth - bar.clientWidth;
  bar.classList.toggle("more-start", bar.scrollLeft > 2);
  bar.classList.toggle("more-end", bar.scrollLeft < max - 2);
}

function init() {
  document.querySelectorAll(".nav-tabs").forEach(bar => {
    updateHints(bar);
    bar.addEventListener("scroll", () => updateHints(bar), { passive: true });
  });
}

document.addEventListener("DOMContentLoaded", init);
window.addEventListener("resize", () => document.querySelectorAll(".nav-tabs").forEach(updateHints));

// Bootstrap fires shown.bs.tab on the tab link once it is active. Scroll it clear of
// the edge fades (scrollIntoView would leave it under one); at either end of the row
// the scroll stops at the end, which also hides that end's hint.
const FADE = 52;

document.addEventListener("shown.bs.tab", e => {
  const bar = e.target.closest(".nav-tabs");
  if (!bar || bar.scrollWidth <= bar.clientWidth) return;

  const tab = e.target.getBoundingClientRect();
  const box = bar.getBoundingClientRect();
  let delta = 0;
  if (tab.right > box.right - FADE) delta = tab.right - (box.right - FADE);
  else if (tab.left < box.left + FADE) delta = tab.left - (box.left + FADE);

  if (delta) bar.scrollBy({ left: delta, behavior: "smooth" });
});
