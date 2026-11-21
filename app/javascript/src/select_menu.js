// Styled dropdowns for every <select class="form-select"> (not multiple, and not
// marked data-native). The real <select> stays in the form, hidden, so submitting,
// labels, change events and other scripts keep working; this draws the button and
// the list on top and writes the choice back to it.
//
// Follows the WAI-ARIA "select-only combobox" pattern: the button is a combobox,
// the list a listbox. Keys: ↓/↑/Enter/Space open, ↓/↑/Home/End move, Enter picks,
// Escape closes, typing jumps to a match (or filters, in lists long enough to have
// a search box). Picking dispatches "change" (and "input") on the <select>.
const SEARCH_FROM = 10;   // options before a search box appears
const RENDER_LIMIT = 300; // most rows drawn at once; typing narrows the rest
const SELECTOR = "select.form-select:not([multiple]):not([data-native])";

let uid = 0;
let openMenu = null;

const optionText = option => option.textContent.replace(/\s+/g, " ").trim();

class SelectMenu {
  constructor(select) {
    this.select = select;
    this.id = `select-menu-${++uid}`;
    this.typed = "";
    this.build();
    this.refresh();
    this.watch();
  }

  // ------------------------------------------------------------ Setup
  build() {
    const select = this.select;
    select.classList.add("select-menu-native");
    select.tabIndex = -1;
    select.setAttribute("aria-hidden", "true");

    this.wrapper = document.createElement("div");
    this.wrapper.className = "select-menu";
    select.after(this.wrapper);

    this.button = document.createElement("button");
    this.button.type = "button";
    this.button.id = `${this.id}-button`;
    // Keep the select's own sizing/spacing classes so layouts don't shift
    this.button.className = `${select.className.replace("select-menu-native", "")} select-menu-button`.trim();
    this.button.setAttribute("role", "combobox");
    this.button.setAttribute("aria-haspopup", "listbox");
    this.button.setAttribute("aria-expanded", "false");
    this.button.setAttribute("aria-controls", `${this.id}-list`);
    this.label();
    this.wrapper.append(this.button);

    this.popup = document.createElement("div");
    this.popup.className = "select-menu-popup";
    this.popup.hidden = true;
    this.list = document.createElement("ul");
    this.list.id = `${this.id}-list`;
    this.list.className = "select-menu-list";
    this.list.setAttribute("role", "listbox");
    this.list.setAttribute("aria-labelledby", this.button.getAttribute("aria-labelledby") || this.button.id);
    this.popup.append(this.list);

    this.button.addEventListener("click", () => (this.isOpen() ? this.close() : this.open()));
    this.button.addEventListener("keydown", e => this.onButtonKey(e));
    // A label click focuses the hidden select: pass that on to the button
    select.addEventListener("focus", () => this.button.focus());
    this.list.addEventListener("mousedown", e => e.preventDefault()); // keep focus where it is
    this.list.addEventListener("click", e => {
      const row = e.target.closest("[role='option']");
      if (row && row.getAttribute("aria-disabled") !== "true") this.choose(Number(row.dataset.index));
    });
    this.list.addEventListener("mousemove", e => {
      const row = e.target.closest("[role='option']");
      if (row && row.getAttribute("aria-disabled") !== "true") this.setActive(Number(row.dataset.index), false);
    });
  }

  // The button is named by the select's <label>s, or its own aria-label
  label() {
    const labels = Array.from(this.select.labels || []);
    if (labels.length) {
      const ids = labels.map((label, i) => label.id || (label.id = `${this.id}-label-${i}`));
      this.button.setAttribute("aria-labelledby", `${ids.join(" ")} ${this.button.id}`);
    } else if (this.select.getAttribute("aria-label")) {
      this.button.setAttribute("aria-label", this.select.getAttribute("aria-label"));
    }
  }

  // Follow the select if something else changes it (a form reset, another script)
  watch() {
    this.select.addEventListener("change", () => this.refresh());
    this.select.form?.addEventListener("reset", () => setTimeout(() => this.refresh()));
    new MutationObserver(() => this.refresh()).observe(this.select, {
      childList: true, subtree: true, attributes: true, attributeFilter: ["disabled", "selected"]
    });
  }

  // ------------------------------------------------------------ State
  options() {
    return Array.from(this.select.options);
  }

  refresh() {
    const chosen = this.select.selectedOptions[0];
    const text = chosen ? optionText(chosen) : "";
    this.button.textContent = text || "Select…";
    this.button.classList.toggle("is-placeholder", !text);
    this.button.disabled = this.select.disabled;
  }

  isOpen() {
    return !this.popup.hidden;
  }

  // ------------------------------------------------------------ Opening and closing
  open(query = "") {
    if (this.select.disabled || this.isOpen()) return;
    if (openMenu) openMenu.close(false);
    openMenu = this;

    // Inside a Bootstrap modal the list has to live in the modal, or its focus trap
    // pulls focus back out of the search box
    (this.select.closest(".modal") || document.body).append(this.popup);
    this.searchable = this.options().length > SEARCH_FROM;
    this.addSearch(query);
    this.render(query);
    this.popup.hidden = false;
    this.button.setAttribute("aria-expanded", "true");
    this.place();
    this.setActive(this.select.selectedIndex >= 0 ? this.select.selectedIndex : this.firstEnabled(), true);
    if (this.search) this.search.focus();

    this.reposition = () => this.place();
    window.addEventListener("resize", this.reposition);
    window.addEventListener("scroll", this.reposition, true);
  }

  close(refocus = true) {
    if (!this.isOpen()) return;
    this.popup.hidden = true;
    this.button.setAttribute("aria-expanded", "false");
    this.button.removeAttribute("aria-activedescendant");
    this.search?.remove();
    this.search = null;
    window.removeEventListener("resize", this.reposition);
    window.removeEventListener("scroll", this.reposition, true);
    if (openMenu === this) openMenu = null;
    if (refocus) this.button.focus();
  }

  addSearch(query) {
    if (!this.searchable) return;

    this.search = document.createElement("input");
    this.search.type = "search";
    this.search.className = "form-control select-menu-search";
    this.search.placeholder = "Type to search…";
    this.search.autocomplete = "off";
    this.search.setAttribute("role", "combobox");
    this.search.setAttribute("aria-label", "Search options");
    this.search.setAttribute("aria-controls", this.list.id);
    this.search.setAttribute("aria-expanded", "true");
    this.search.setAttribute("aria-autocomplete", "list");
    this.search.value = query;
    this.search.addEventListener("input", () => {
      this.render(this.search.value);
      this.setActive(this.firstVisible(), true);
    });
    this.search.addEventListener("keydown", e => this.onListKey(e));
    this.popup.prepend(this.search);
  }

  // Below the button, or above it when there isn't room; at least as wide as it
  place() {
    const box = this.button.getBoundingClientRect();
    const popup = this.popup;
    popup.style.minWidth = `${box.width}px`;
    popup.style.left = `${Math.max(8, Math.min(box.left, window.innerWidth - popup.offsetWidth - 8))}px`;

    const below = window.innerHeight - box.bottom;
    const above = box.top;
    const height = Math.min(popup.scrollHeight, 320);
    if (below < height + 12 && above > below) {
      popup.style.top = "";
      popup.style.bottom = `${window.innerHeight - box.top + 4}px`;
      popup.style.maxHeight = `${Math.min(320, above - 12)}px`;
    } else {
      popup.style.bottom = "";
      popup.style.top = `${box.bottom + 4}px`;
      popup.style.maxHeight = `${Math.min(320, below - 12)}px`;
    }
  }

  // ------------------------------------------------------------ Drawing the list
  render(query = "") {
    const needle = query.trim().toLowerCase();
    const rows = [];
    let shown = 0;
    let matches = 0;
    let group = null;

    this.options().forEach((option, index) => {
      const text = optionText(option);
      if (needle && !text.toLowerCase().includes(needle)) return;
      matches += 1;
      if (shown >= RENDER_LIMIT) return;

      const parent = option.parentElement;
      if (parent.tagName === "OPTGROUP" && parent !== group) {
        group = parent;
        const heading = document.createElement("li");
        heading.className = "select-menu-group";
        heading.setAttribute("role", "presentation");
        heading.textContent = parent.label;
        rows.push(heading);
      } else if (parent.tagName !== "OPTGROUP") {
        group = null;
      }

      const row = document.createElement("li");
      row.id = `${this.id}-option-${index}`;
      row.dataset.index = index;
      row.className = "select-menu-option";
      row.setAttribute("role", "option");
      row.setAttribute("aria-selected", String(option.selected));
      if (option.disabled || parent.disabled) row.setAttribute("aria-disabled", "true");
      if (parent.tagName === "OPTGROUP") row.classList.add("in-group");
      row.textContent = text || " "; // a blank choice still gets a row
      if (!text) row.classList.add("is-blank");
      rows.push(row);
      shown += 1;
    });

    if (matches === 0) {
      const empty = document.createElement("li");
      empty.className = "select-menu-note";
      empty.textContent = "No matches";
      rows.push(empty);
    } else if (matches > shown) {
      const more = document.createElement("li");
      more.className = "select-menu-note";
      more.textContent = `Showing ${shown} of ${matches}. Type to narrow it down.`;
      rows.push(more);
    }
    this.list.replaceChildren(...rows);
  }

  rows() {
    return Array.from(this.list.querySelectorAll("[role='option']:not([aria-disabled='true'])"));
  }

  firstEnabled() {
    return this.options().findIndex(option => !option.disabled);
  }

  firstVisible() {
    const row = this.rows()[0];
    return row ? Number(row.dataset.index) : -1;
  }

  setActive(index, scroll) {
    this.active = index;
    this.list.querySelectorAll(".is-active").forEach(row => row.classList.remove("is-active"));
    const row = this.list.querySelector(`[data-index='${index}']`);
    const owner = this.search || this.button;
    if (!row) {
      owner.removeAttribute("aria-activedescendant");
      return;
    }
    row.classList.add("is-active");
    owner.setAttribute("aria-activedescendant", row.id);
    if (scroll) row.scrollIntoView({ block: "nearest" });
  }

  move(step) {
    const rows = this.rows();
    if (!rows.length) return;

    const at = rows.findIndex(row => Number(row.dataset.index) === this.active);
    let next;
    if (step === "first") next = 0;
    else if (step === "last") next = rows.length - 1;
    else next = at === -1 ? 0 : Math.min(rows.length - 1, Math.max(0, at + step));
    this.setActive(Number(rows[next].dataset.index), true);
  }

  choose(index) {
    const option = this.select.options[index];
    if (!option || option.disabled) return;

    const changed = this.select.selectedIndex !== index;
    this.select.selectedIndex = index;
    this.refresh();
    this.close();
    if (changed) {
      this.select.dispatchEvent(new Event("input", { bubbles: true }));
      this.select.dispatchEvent(new Event("change", { bubbles: true }));
    }
  }

  // Jump to the next option starting with what's been typed (lists without search)
  typeahead(key) {
    clearTimeout(this.typedTimer);
    this.typed += key.toLowerCase();
    this.typedTimer = setTimeout(() => { this.typed = ""; }, 600);

    const options = this.options();
    const start = Math.max(0, this.isOpen() ? this.active : this.select.selectedIndex);
    for (let step = 1; step <= options.length; step += 1) {
      const index = (start + step) % options.length;
      if (!options[index].disabled && optionText(options[index]).toLowerCase().startsWith(this.typed)) {
        if (this.isOpen()) this.setActive(index, true);
        else this.choose(index);
        return;
      }
    }
  }

  // ------------------------------------------------------------ Keys
  onButtonKey(e) {
    const printable = e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey;

    if (!this.isOpen()) {
      if (["ArrowDown", "ArrowUp", "Enter", " "].includes(e.key)) {
        e.preventDefault();
        this.open();
      } else if (printable) {
        e.preventDefault();
        if (this.options().length > SEARCH_FROM) this.open(e.key);
        else this.typeahead(e.key);
      }
      return;
    }

    if (printable && e.key !== " ") {
      e.preventDefault();
      this.typeahead(e.key);
    } else {
      this.onListKey(e);
    }
  }

  onListKey(e) {
    switch (e.key) {
      case "ArrowDown": e.preventDefault(); this.move(1); break;
      case "ArrowUp": e.preventDefault(); this.move(-1); break;
      case "Home": if (!this.search) { e.preventDefault(); this.move("first"); } break;
      case "End": if (!this.search) { e.preventDefault(); this.move("last"); } break;
      case "PageDown": e.preventDefault(); this.move(8); break;
      case "PageUp": e.preventDefault(); this.move(-8); break;
      case "Enter":
      case " ":
        if (e.key === " " && this.search) return; // a space is part of the search
        e.preventDefault();
        if (this.active >= 0) this.choose(this.active);
        break;
      case "Escape":
        e.preventDefault();
        e.stopPropagation(); // don't also close a modal around it
        this.close();
        break;
      case "Tab":
        this.close(false);
        break;
      default:
    }
  }
}

function enhance(root = document) {
  const selects = root.matches?.(SELECTOR) ? [root] : root.querySelectorAll?.(SELECTOR) || [];
  selects.forEach(select => {
    if (!select.classList.contains("select-menu-native")) new SelectMenu(select);
  });
}

// A click anywhere else closes the open list
document.addEventListener("mousedown", e => {
  if (openMenu && !openMenu.popup.contains(e.target) && !openMenu.wrapper.contains(e.target)) openMenu.close(false);
});

// Closing a modal closes a list open inside it
document.addEventListener("hide.bs.modal", () => openMenu?.close(false));

$(() => {
  enhance();
  // Selects that arrive later (search results, drawers filled by AJAX)
  new MutationObserver(records => {
    records.forEach(record => record.addedNodes.forEach(node => {
      if (node.nodeType === Node.ELEMENT_NODE) enhance(node);
    }));
  }).observe(document.body, { childList: true, subtree: true });
});
