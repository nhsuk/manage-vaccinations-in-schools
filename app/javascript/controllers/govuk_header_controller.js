import { Controller } from "@hotwired/stimulus";
import { Header } from "govuk-frontend";

// Connects to data-module="govuk-header"
export default class extends Controller {
  connect() {
    new Header(this.element).init();
  }
}
