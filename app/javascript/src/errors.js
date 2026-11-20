// Flash messages clear themselves after 10 seconds
document.addEventListener("DOMContentLoaded", () => {
  setTimeout(() => {
    document.querySelectorAll(".flash").forEach(el => el.remove());
  }, 10000);
});
