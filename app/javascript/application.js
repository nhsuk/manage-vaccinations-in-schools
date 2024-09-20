import "@hotwired/turbo-rails";
// import { initServiceWorker } from "./serviceworker-companion";
import "./controllers";
import dfeAutocomplete from "dfe-autocomplete";

Turbo.session.drive = false;

// initServiceWorker();
function shimAutocomplete() {
  document
    .querySelectorAll('[data-module="app-dfe-autocomplete"]')
    .forEach((element) => {
      const nhsukFormGroup = element.querySelector("div.nhsuk-form-group");
      if (nhsukFormGroup) {
        nhsukFormGroup.classList.add("govuk-form-group");
      }
    });
}

shimAutocomplete();
dfeAutocomplete({});
