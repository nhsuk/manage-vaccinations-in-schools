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
        <input type="hidden" name="cohort_import[changesets_attributes][0][id]" value="479" />
        <input type="hidden" name="cohort_import[changesets_attributes][0][decision]" value="" />
        <input type="radio" name="cohort_import[changesets_attributes][0][decision]" value="apply" />
        <input type="radio" name="cohort_import[changesets_attributes][0][decision]" value="discard" />
        <input type="radio" name="cohort_import[changesets_attributes][0][decision]" value="keep_both" />

        <!-- Changeset 2 -->
        <input type="hidden" name="cohort_import[changesets_attributes][1][id]" value="480" />
        <input type="hidden" name="cohort_import[changesets_attributes][1][decision]" value="" />
        <input type="radio" name="cohort_import[changesets_attributes][1][decision]" value="apply" />
        <input type="radio" name="cohort_import[changesets_attributes][1][decision]" value="discard" />
        <input type="radio" name="cohort_import[changesets_attributes][1][decision]" value="keep_both" />
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
        'input[type="radio"][value="apply"]',
      );
      radio.checked = true;
      radio.dispatchEvent(new Event("change", { bubbles: true }));

      const stored = JSON.parse(
        localStorage.getItem("cohort_import_23_decisions"),
      );
      expect(stored["479"]).toBe("apply");
    });

    test("should update existing decision when changed", () => {
      const applyRadio = document.querySelector(
        'input[type="radio"][value="apply"]',
      );
      applyRadio.checked = true;
      applyRadio.dispatchEvent(new Event("change", { bubbles: true }));

      let stored = JSON.parse(
        localStorage.getItem("cohort_import_23_decisions"),
      );
      expect(stored["479"]).toBe("apply");

      const discardRadio = document.querySelector(
        'input[type="radio"][value="discard"]',
      );
      discardRadio.checked = true;
      discardRadio.dispatchEvent(new Event("change", { bubbles: true }));

      stored = JSON.parse(localStorage.getItem("cohort_import_23_decisions"));
      expect(stored["479"]).toBe("discard");
    });

    test("should save multiple decisions", () => {
      const radio1 = document.querySelector(
        'input[name="cohort_import[changesets_attributes][0][decision]"][value="apply"]',
      );
      radio1.checked = true;
      radio1.dispatchEvent(new Event("change", { bubbles: true }));

      const radio2 = document.querySelector(
        'input[name="cohort_import[changesets_attributes][1][decision]"][value="discard"]',
      );
      radio2.checked = true;
      radio2.dispatchEvent(new Event("change", { bubbles: true }));

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

      const allRadios = form.querySelectorAll('input[type="radio"]');

      const radio1 = Array.from(allRadios).find(
        (r) =>
          r.name === "cohort_import[changesets_attributes][0][decision]" &&
          r.value === "apply",
      );

      const radio2 = Array.from(allRadios).find(
        (r) =>
          r.name === "cohort_import[changesets_attributes][1][decision]" &&
          r.value === "discard",
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
        'input[type="hidden"][name="cohort_import[changesets_attributes][0][decision]"]',
      );
      expect(hiddenField.value).toBe("keep_both");
    });

    test("should handle empty localStorage", () => {
      initializeComponent();

      const decisions = component.getDecisions();
      expect(decisions).toEqual({});
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
        'input[type="hidden"][name="cohort_import[changesets_attributes][0][decision]"]',
      );
      const hidden2 = document.querySelector(
        'input[type="hidden"][name="cohort_import[changesets_attributes][1][decision]"]',
      );

      expect(hidden1.value).toBe("apply");
      expect(hidden2.value).toBe("discard");
    });
  });

  describe("getChangesetId", () => {
    beforeEach(() => {
      initializeComponent();
    });

    test("should extract changeset ID from radio input", () => {
      const radio = document.querySelector('input[type="radio"]');
      const changesetId = component.getChangesetId(radio);
      expect(changesetId).toBe("479");
    });

    test("should return null for invalid input", () => {
      const input = document.createElement("input");
      input.name = "invalid_name";
      const changesetId = component.getChangesetId(input);
      expect(changesetId).toBeNull();
    });
  });

  describe("extractArrayIndex", () => {
    beforeEach(() => {
      initializeComponent();
    });

    test("should extract array index from changesets_attributes", () => {
      const name = "cohort_import[changesets_attributes][0][decision]";
      const index = component.extractArrayIndex(name);
      expect(index).toBe("0");
    });

    test("should extract array index from changesets", () => {
      const name = "cohort_import[changesets][5][decision]";
      const index = component.extractArrayIndex(name);
      expect(index).toBe("5");
    });

    test("should return null for invalid name", () => {
      const name = "invalid_name";
      const index = component.extractArrayIndex(name);
      expect(index).toBeNull();
    });
  });
});
