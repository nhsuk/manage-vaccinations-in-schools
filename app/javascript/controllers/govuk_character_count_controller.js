import { Controller } from "@hotwired/stimulus";
import { CharacterCount } from "govuk-frontend";

// Connects to data-module="govuk-character-count"
export default class extends Controller {
  connect() {
    new CharacterCount(this.element).init();
  }
}
