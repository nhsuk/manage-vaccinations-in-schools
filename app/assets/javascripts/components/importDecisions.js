import { Component } from "nhsuk-frontend";

export class ImportDecisions extends Component {
  static elementType = HTMLFormElement;
  static moduleName = "app-import-decisions";

  constructor($root) {
    super($root);

    if (!($root instanceof HTMLFormElement)) {
      return;
    }

    this.importType = this.$root.dataset.importType;
    this.importId = this.$root.dataset.importId;
    this.storageKey = `${this.importType}_${this.importId}_decisions`;

    this.decisionsCache = null;

    this.restoreDecisions();
    this.bindEvents();
  }

  bindEvents() {
    // Save decision when radio changes
    this.$root.addEventListener("change", (e) => {
      if (e.target.type === "radio" && e.target.name.includes("[decision]")) {
        this.saveDecision(e.target);
      }
    });

    // Populate hidden fields before submit
    this.$root.addEventListener("submit", () => {
      this.populateHiddenFields();
    });
  }

  saveDecision(radio) {
    const changesetId = this.getChangesetId(radio);

    if (!changesetId) return;

    const decisions = this.getDecisions();
    decisions[changesetId] = radio.value;

    this.setDecisions(decisions);
  }

  restoreDecisions() {
    const decisions = this.getDecisions();

    Object.entries(decisions).forEach(([changesetId, decision]) => {
      const idField = this.$root.querySelector(
        `input[type="hidden"][value="${changesetId}"][name*="[id]"]`,
      );
      if (!idField) return;

      const arrayIndex = this.extractArrayIndex(idField.name);
      if (!arrayIndex) return;

      const radio = this.$root.querySelector(
        `input[type="radio"][name*="[${arrayIndex}][decision]"][value="${decision}"]`,
      );
      if (radio) {
        radio.checked = true;
      }

      const hiddenField = this.$root.querySelector(
        `input[type="hidden"][name*="[${arrayIndex}][decision]"]`,
      );
      if (hiddenField) {
        hiddenField.value = decision;
      }
    });
  }

  populateHiddenFields() {
    const decisions = this.getDecisions();

    this.$root
      .querySelectorAll('input[type="hidden"][name*="[decision]"]')
      .forEach((hiddenField) => {
        const changesetId = this.getChangesetId(hiddenField);
        if (changesetId && decisions[changesetId]) {
          hiddenField.value = decisions[changesetId];
        }
      });
  }

  getDecisions() {
    if (this.decisionsCache === null) {
      this.decisionsCache = JSON.parse(
        localStorage.getItem(this.storageKey) || "{}",
      );
    }
    return this.decisionsCache;
  }

  setDecisions(decisions) {
    this.decisionsCache = decisions;
    localStorage.setItem(this.storageKey, JSON.stringify(decisions));
  }

  getChangesetId(input) {
    const arrayIndex = this.extractArrayIndex(input.name);
    if (!arrayIndex) return null;

    const idField = this.$root.querySelector(
      `input[type="hidden"][name*="[${arrayIndex}][id]"]`,
    );
    return idField ? idField.value : null;
  }

  extractArrayIndex(name) {
    const match = name.match(/\[changesets(?:_attributes)?\]\[(\d+)\]/);
    return match ? match[1] : null;
  }
}
