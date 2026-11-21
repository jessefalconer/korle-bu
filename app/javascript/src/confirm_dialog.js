import Rails from "@rails/ujs";

// Rails asks before acting on any element with data-confirm (every Delete button).
// Instead of the browser's confirm() box, show the in-app dialog. Rails needs a yes/no
// answer straight away, so say "no", open the dialog, and if the person confirms, click
// the element again; that second time it is waved through.
const dialog = () => document.getElementById("confirm-dialog");
let approved = null;

function ask(message, element) {
  const box = dialog();
  if (!box || typeof box.showModal !== "function") return Promise.resolve(window.confirm(message));

  box.querySelector(".confirm-dialog-message").textContent = message;
  // The confirm button repeats the action's own label ("Delete", "Remove", …)
  const label = element.textContent.trim() || "Confirm";
  box.querySelector(".confirm-dialog-accept-label").textContent = label;
  box.querySelector(".confirm-dialog-title").textContent = `${label}?`;

  box.returnValue = "";
  box.showModal();
  box.querySelector(".btn-cancel").focus(); // the safe choice has focus

  return new Promise(resolve => {
    box.addEventListener("close", () => resolve(box.returnValue === "confirm"), { once: true });
  });
}

Rails.confirm = (message, element) => {
  if (approved === element) {
    approved = null;
    return true;
  }

  ask(message, element).then(ok => {
    if (!ok) return;
    approved = element;
    element.click();
  });
  return false;
};

// Clicking the dimmed backdrop (outside the card) cancels, like the other modals
document.addEventListener("click", e => {
  const box = dialog();
  if (box && e.target === box) box.close("cancel");
});
