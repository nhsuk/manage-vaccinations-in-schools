import { Controller } from "@hotwired/stimulus";
import { Checkboxes } from "govuk-frontend";

// Connects to data-module="govuk-checkboxes"
export default class extends Controller {
  connect() {
    new Checkboxes(this.element).init();
  }
}
