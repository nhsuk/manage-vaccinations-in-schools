import { ImportDecisions } from "./importDecisions.js";

jest.mock("nhsuk-frontend", () => ({
  Component: class MockComponent {
    constructor($root) {
      this.$root = $root;
    }
  },
}));

describe("ImportDecisions", () => {
  let form;
  let component;

  beforeEach(() => {
    localStorage.clear();

    document.body.innerHTML = `
      <form 
        data-module="app-import-decisions"
        data-import-type="cohort_import"
        data-import-id="23"
      >
        <!-- Changeset 1 -->
        <div data-changeset-id="479">
          <input type="hidden" name="cohort_import[changesets_attributes][0][id]" value="479" />
          <input type="hidden" name="cohort_import[changesets_attributes][0][decision]" value="" data-changeset-id="479" />
          <input type="radio" name="cohort_import[changesets_attributes][0][decision]" value="apply" />
          <input type="radio" name="cohort_import[changesets_attributes][0][decision]" value="discard" />
          <input type="radio" name="cohort_import[changesets_attributes][0][decision]" value="keep_both" />
        </div>

        <!-- Changeset 2 -->
        <div data-changeset-id="480">
          <input type="hidden" name="cohort_import[changesets_attributes][1][id]" value="480" />
          <input type="hidden" name="cohort_import[changesets_attributes][1][decision]" value="" data-changeset-id="480" />
          <input type="radio" name="cohort_import[changesets_attributes][1][decision]" value="apply" />
          <input type="radio" name="cohort_import[changesets_attributes][1][decision]" value="discard" />
          <input type="radio" name="cohort_import[changesets_attributes][1][decision]" value="keep_both" />
        </div>
      </form>
    `;

    form = document.querySelector('form[data-module="app-import-decisions"]');
  });

  afterEach(() => {
    localStorage.clear();
  });

  const initializeComponent = () => {
    component = new ImportDecisions(form);
  };

  describe("initialization", () => {
    beforeEach(() => {
      initializeComponent();
    });

    test("should initialize with correct storage key", () => {
      expect(component.storageKey).toBe("cohort_import_23_decisions");
    });

    test("should initialize with correct import type", () => {
      expect(component.importType).toBe("cohort_import");
    });

    test("should initialize with correct import id", () => {
      expect(component.importId).toBe("23");
    });

    test("should not initialize if root is not a form", () => {
      const div = document.createElement("div");
      const nonFormComponent = new ImportDecisions(div);
      expect(nonFormComponent.storageKey).toBeUndefined();
    });
  });

  describe("saveDecision", () => {
    beforeEach(() => {
      initializeComponent();
    });

    test("should save decision to localStorage", () => {
      const radio = document.querySelector(
        '[data-changeset-id="479"] input[type="radio"][value="apply"]',
      );
      radio.click();

      const stored = JSON.parse(
        localStorage.getItem("cohort_import_23_decisions"),
      );
      expect(stored["479"]).toBe("apply");
    });

    test("should update existing decision when changed", () => {
      const applyRadio = document.querySelector(
        '[data-changeset-id="479"] input[type="radio"][value="apply"]',
      );
      applyRadio.click();

      let stored = JSON.parse(
        localStorage.getItem("cohort_import_23_decisions"),
      );
      expect(stored["479"]).toBe("apply");

      const discardRadio = document.querySelector(
        '[data-changeset-id="479"] input[type="radio"][value="discard"]',
      );
      discardRadio.click();

      stored = JSON.parse(localStorage.getItem("cohort_import_23_decisions"));
      expect(stored["479"]).toBe("discard");
    });

    test("should save multiple decisions", () => {
      const radio1 = document.querySelector(
        '[data-changeset-id="479"] input[type="radio"][value="apply"]',
      );
      radio1.click();

      const radio2 = document.querySelector(
        '[data-changeset-id="480"] input[type="radio"][value="discard"]',
      );
      radio2.click();

      const stored = JSON.parse(
        localStorage.getItem("cohort_import_23_decisions"),
      );
      expect(stored["479"]).toBe("apply");
      expect(stored["480"]).toBe("discard");
    });
  });

  describe("restoreDecisions", () => {
    test("should restore decisions from localStorage", () => {
      localStorage.setItem(
        "cohort_import_23_decisions",
        JSON.stringify({ 479: "apply", 480: "discard" }),
      );

      initializeComponent();

      const radio1 = document.querySelector(
        '[data-changeset-id="479"] input[type="radio"][value="apply"]',
      );
      const radio2 = document.querySelector(
        '[data-changeset-id="480"] input[type="radio"][value="discard"]',
      );

      expect(radio1.checked).toBe(true);
      expect(radio2.checked).toBe(true);
    });

    test("should restore hidden field values", () => {
      localStorage.setItem(
        "cohort_import_23_decisions",
        JSON.stringify({ 479: "keep_both" }),
      );

      initializeComponent();

      const hiddenField = document.querySelector(
        'input[type="hidden"][name*="[decision]"][data-changeset-id="479"]',
      );
      expect(hiddenField.value).toBe("keep_both");
    });

    test("should handle empty localStorage", () => {
      initializeComponent();

      const decisions = component.getDecisions();
      expect(decisions).toEqual({});
    });

    test("should not fail if changeset not found in DOM", () => {
      localStorage.setItem(
        "cohort_import_23_decisions",
        JSON.stringify({ 479: "apply", 999: "discard" }),
      );

      expect(() => initializeComponent()).not.toThrow();

      const radio1 = document.querySelector(
        '[data-changeset-id="479"] input[type="radio"][value="apply"]',
      );
      expect(radio1.checked).toBe(true);
    });
  });

  describe("populateHiddenFields", () => {
    test("should populate hidden fields on submit", () => {
      localStorage.setItem(
        "cohort_import_23_decisions",
        JSON.stringify({ 479: "apply", 480: "discard" }),
      );

      initializeComponent();

      form.dispatchEvent(new Event("submit"));

      const hidden1 = document.querySelector(
        'input[type="hidden"][data-changeset-id="479"]',
      );
      const hidden2 = document.querySelector(
        'input[type="hidden"][data-changeset-id="480"]',
      );

      expect(hidden1.value).toBe("apply");
      expect(hidden2.value).toBe("discard");
    });

    test("should only populate fields that exist in DOM", () => {
      localStorage.setItem(
        "cohort_import_23_decisions",
        JSON.stringify({ 479: "apply", 999: "discard" }),
      );

      initializeComponent();

      expect(() => form.dispatchEvent(new Event("submit"))).not.toThrow();

      const hidden1 = document.querySelector(
        'input[type="hidden"][data-changeset-id="479"]',
      );
      expect(hidden1.value).toBe("apply");
    });
  });

  describe("getDecisions and setDecisions", () => {
    beforeEach(() => {
      initializeComponent();
    });

    test("should get decisions from localStorage", () => {
      localStorage.setItem(
        "cohort_import_23_decisions",
        JSON.stringify({ 479: "apply" }),
      );

      const decisions = component.getDecisions();
      expect(decisions).toEqual({ 479: "apply" });
    });

    test("should set decisions to localStorage", () => {
      component.setDecisions({ 479: "apply", 480: "discard" });

      const stored = JSON.parse(
        localStorage.getItem("cohort_import_23_decisions"),
      );
      expect(stored).toEqual({ 479: "apply", 480: "discard" });
    });

    test("should return empty object if localStorage is empty", () => {
      const decisions = component.getDecisions();
      expect(decisions).toEqual({});
    });
  });
});
