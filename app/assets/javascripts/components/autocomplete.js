import accessibleAutocomplete from "accessible-autocomplete";
import { Component } from "nhsuk-frontend";

/**
 * Autocomplete component
 *
 * @augments Component<HTMLSelectElement>
 */
export class Autocomplete extends Component {
  static elementType = HTMLSelectElement;

  /**
   * @param {Element | null} $root - HTML element to use for component
   */
  constructor($root) {
    super($root);

    this.name = this.$root.name;
    this.options = Array.from(this.$root.options);
    this.value = this.$root.value;
    this.disableHints = this.$root.dataset.disablehints === "true";

    this.enhanceSelectElement(this.$root);
  }

  /**
   * Name for the component used when initialising using data-module attributes
   */
  static moduleName = "app-autocomplete";

  /**
   * Enhance select element
   *
   * @param {HTMLSelectElement} $element - Select element to enhance
   */
  enhanceSelectElement($element) {
    accessibleAutocomplete.enhanceSelectElement({
      selectElement: $element,
      cssNamespace: "app-autocomplete",
      defaultValue: this.value || "",
      inputClasses: "nhsuk-input",
      showNoOptionsFound: true,
      templates: {
        suggestion: this.disableHints
          ? undefined
          : (value) => this.suggestion(value),
      },
      onConfirm: (value) => {
        const selectedOption = this.options.filter(
          (option) => (option.textContent || option.innerText) === value,
        )[0];

        if (selectedOption) {
          selectedOption.selected = true;
        }
      },
    });
  }

  /**
   * HTML for suggestion
   *
   * @param {*} value - Current value
   * @returns {string} HTML for suggestion
   */
  suggestion(value) {
    const option = this.options.find(({ label }) => label === value);
    if (option) {
      return option.dataset.hint
        ? `${value}<br><span class="app-autocomplete__option-hint">${option.dataset.hint}</span>`
        : value;
    }
    return "No results found";
  }
}
