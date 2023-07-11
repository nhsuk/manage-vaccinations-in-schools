import { Controller } from "@hotwired/stimulus";
import { Radios } from "govuk-frontend";

// Connects to data-module="govuk-radios"
export default class extends Controller {
  connect() {
    new Radios(this.element).init();
  }
}
