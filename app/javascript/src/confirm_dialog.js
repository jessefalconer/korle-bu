import Rails from "@rails/ujs";

// Rails asks before acting on any element with data-confirm (every Delete button).
// Instead of the browser's confirm() box, show the in-app dialog. Rails needs a yes/no
// answer straight away, so say "no", open the dialog, and if the person confirms, click
// the element again; that second time it is waved through.
//
// A button with data-confirm-word (deleting something that holds other records) also
// lists data-confirm-details and keeps Delete disabled until the word is typed. The
// typed word is sent along as ?confirm_delete=..., which the server checks too.
const dialog = () => document.getElementById("confirm-dialog");
let approved = null;

function showDetails(box, details) {
  const list = box.querySelector(".confirm-dialog-details");
  list.replaceChildren(...details.map(text => {
    const li = document.createElement("li");
    li.textContent = text;
    return li;
  }));
  list.hidden = details.length === 0;
}

function setUpTypedWord(box, word) {
  const section = box.querySelector(".confirm-dialog-typed");
  const input = box.querySelector("#confirm-dialog-word");
  const accept = box.querySelector(".confirm-dialog-accept");

  section.hidden = !word;
  input.value = "";
  accept.disabled = Boolean(word);
  box.dataset.word = word || "";
}

function typedWordMatches(box) {
  const word = box.dataset.word;
  return !word || box.querySelector("#confirm-dialog-word").value.trim().toLowerCase() === word;
}

function ask(message, element) {
  const box = dialog();
  if (!box || typeof box.showModal !== "function") return Promise.resolve(window.confirm(message));

  box.querySelector(".confirm-dialog-message").textContent = message;
  // The confirm button repeats the action's own label ("Delete", "Remove", …)
  const label = element.textContent.trim() || "Confirm";
  box.querySelector(".confirm-dialog-accept-label").textContent = label;
  box.querySelector(".confirm-dialog-title").textContent = `${label}?`;

  let details = [];
  try { details = JSON.parse(element.dataset.confirmDetails || "[]"); } catch (_e) { /* none */ }
  showDetails(box, details);
  const word = element.dataset.confirmWord;
  setUpTypedWord(box, word);

  box.returnValue = "";
  box.showModal();
  // The safe choice has focus, or the box to type in when one is needed
  (word ? box.querySelector("#confirm-dialog-word") : box.querySelector(".btn-cancel")).focus();

  return new Promise(resolve => {
    box.addEventListener("close", () => resolve(box.returnValue === "confirm" && typedWordMatches(box)), { once: true });
  });
}

// The server only accepts the delete with the typed word attached
function withTypedWord(element) {
  const word = element.dataset.confirmWord;
  if (!word || !element.href) return;

  const url = new URL(element.href, window.location.href);
  url.searchParams.set("confirm_delete", word);
  element.href = url.toString();
}

Rails.confirm = (message, element) => {
  if (approved === element) {
    approved = null;
    return true;
  }

  ask(message, element).then(ok => {
    if (!ok) return;
    withTypedWord(element);
    approved = element;
    element.click();
  });
  return false;
};

document.addEventListener("input", e => {
  if (e.target.id !== "confirm-dialog-word") return;

  const box = dialog();
  box.querySelector(".confirm-dialog-accept").disabled = !typedWordMatches(box);
});

// Enter in the typing box confirms (when the word matches) instead of submitting
// the dialog's first button, which is Cancel
document.addEventListener("keydown", e => {
  if (e.target.id !== "confirm-dialog-word" || e.key !== "Enter") return;

  e.preventDefault();
  const box = dialog();
  if (typedWordMatches(box)) box.close("confirm");
});

// Clicking the dimmed backdrop (outside the card) cancels, like the other modals
document.addEventListener("click", e => {
  const box = dialog();
  if (box && e.target === box) box.close("cancel");
});
