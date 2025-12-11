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

    this.restoreDecisions();
    this.bindEvents();
  }

  bindEvents() {
    this.$root.addEventListener("change", (e) => {
      if (e.target.type === "radio" && e.target.name.includes("[decision]")) {
        this.saveDecision(e.target);
      }
    });

    this.$root.addEventListener("submit", () => {
      this.populateHiddenFields();
    });
  }

  saveDecision(radio) {
    const changesetId = radio.closest("[data-changeset-id]")?.dataset
      .changesetId;

    if (!changesetId) return;

    const decisions = this.getDecisions();
    decisions[changesetId] = radio.value;
    this.setDecisions(decisions);
  }

  restoreDecisions() {
    const decisions = this.getDecisions();

    Object.entries(decisions).forEach(([changesetId, decision]) => {
      const radio = this.$root.querySelector(
        `[data-changeset-id="${changesetId}"] input[type="radio"][value="${decision}"]`,
      );
      if (radio) {
        radio.checked = true;
      }

      const hiddenField = this.$root.querySelector(
        `input[type="hidden"][name*="[decision]"][data-changeset-id="${changesetId}"]`,
      );
      if (hiddenField) {
        hiddenField.value = decision;
      }
    });
  }

  populateHiddenFields() {
    const decisions = this.getDecisions();

    Object.entries(decisions).forEach(([changesetId, decision]) => {
      const hiddenField = this.$root.querySelector(
        `input[type="hidden"][name*="[decision]"][data-changeset-id="${changesetId}"]`,
      );
      if (hiddenField) {
        hiddenField.value = decision;
      }
    });
  }

  getDecisions() {
    return JSON.parse(localStorage.getItem(this.storageKey) || "{}");
  }

  setDecisions(decisions) {
    localStorage.setItem(this.storageKey, JSON.stringify(decisions));
  }
}
