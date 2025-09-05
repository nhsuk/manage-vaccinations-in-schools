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

    if ($root instanceof HTMLSelectElement) {
      this.name = this.$root.name;
      this.options = Array.from(this.$root.options);
      this.value = this.$root.value;

      this.enhanceSelectElement(this.$root);
    }
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
        suggestion: (value) => this.suggestion(value, this.enhancedOptions),
      },
      onConfirm: (value) => {
        const selectedOption = this.selectedOption(value, this.options);

        if (selectedOption) {
          selectedOption.selected = true;
        }
      },
    });
  }

  /**
   * Get enhanced information about each option
   *
   * @returns {object} Enhanced options
   */
  get enhancedOptions() {
    return this.options.map((option) => ({
      name: option.label,
      value: option.value,
      append: option.getAttribute("data-append"),
      hint: option.getAttribute("data-hint"),
    }));
  }

  /**
   * Selected option
   *
   * @param {*} value - Current value
   * @param {Array} options - Available options
   * @returns {HTMLOptionElement} Selected option
   */
  selectedOption(value, options) {
    return [].filter.call(
      options,
      (option) => (option.textContent || option.innerText) === value,
    )[0];
  }

  /**
   * HTML for suggestion
   *
   * @param {*} value - Current value
   * @param {Array} options - Available options
   * @returns {string} HTML for suggestion
   */
  suggestion(value, options) {
    const option = options.find(({ name }) => name === value);
    if (option) {
      const label = option.append ? `${value} – ${option.append}` : value;
      return option.hint
        ? `${label}<br><span class="app-autocomplete__option-hint">${option.hint}</span>`
        : label;
    }
    return "No results found";
  }
}
