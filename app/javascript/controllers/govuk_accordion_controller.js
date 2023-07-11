import { Controller } from "@hotwired/stimulus";
import { Accordion } from "govuk-frontend";

// Connects to data-module="govuk-accordion"
export default class extends Controller {
  connect() {
    new Accordion(this.element).init();
  }
}
