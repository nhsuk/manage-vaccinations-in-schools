import { Controller } from "@hotwired/stimulus";
import accessibleAutocomplete from "accessible-autocomplete";

const enhanceOption = (option) => {
  return {
    name: option.label,
    append: option.getAttribute("data-append"),
    hint: option.getAttribute("data-hint"),
  };
};

const suggestion = (value, options) => {
  const option = options.find(({ name }) => name === value);
  if (option) {
    const html = option.append ? `${value} – ${option.append}` : value;
    return option.hint
      ? `${html}<br><span class="autocomplete__option-hint">${option.hint}</span>`
      : html;
  } else {
    return "No results found";
  }
};

const autocomplete = ($module) => {
  if (!$module) {
    return;
  }

  const params = $module.dataset;

  const selectOptions = Array.from($module.options);
  const options = selectOptions.map((option) => enhanceOption(option));

  accessibleAutocomplete.enhanceSelectElement({
    autoselect: params.autoselect === "true",
    defaultValue: params.defaultValue || "",
    displayMenu: params.displayMenu,
    minLength: params.minLength ? parseInt(params.minLength) : 0,
    selectElement: $module,
    showAllValues: params.showAllValues === "true",
    showNoOptionsFound: params.showNoOptionsFound === "true",
    templates: {
      suggestion: (value) => suggestion(value, options),
    },
    onConfirm: (value) => {
      const selectedOption = [].filter.call(
        selectOptions,
        (option) => (option.textContent || option.innerText) === value,
      )[0];
      if (selectedOption) selectedOption.selected = true;
    },
  });
};

// Connects to data-module="autocomplete"
export default class extends Controller {
  connect() {
    autocomplete(this.element);
  }
}
