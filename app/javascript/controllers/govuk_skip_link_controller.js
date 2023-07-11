import { Controller } from "@hotwired/stimulus";
import { SkipLink } from "govuk-frontend";

// Connects to data-module="govuk-skip-link"
export default class extends Controller {
  connect() {
    new SkipLink(this.element).init();
  }
}
