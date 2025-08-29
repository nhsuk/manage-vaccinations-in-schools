import { Controller } from "@hotwired/stimulus";
import { Button } from "nhsuk-frontend";

// Connects to data-module="nhsuk-button"
export default class extends Controller {
  connect() {
    return new Button(this.element);
  }
}
