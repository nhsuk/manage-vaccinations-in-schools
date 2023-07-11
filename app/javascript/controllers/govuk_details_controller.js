import { Controller } from "@hotwired/stimulus";
import { Details } from "govuk-frontend";

// Connects to data-module="govuk-details"
export default class extends Controller {
  connect() {
    new Details(this.element).init();
  }
}
