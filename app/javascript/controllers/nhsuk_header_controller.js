import { Controller } from "@hotwired/stimulus";
import { Header } from "nhsuk-frontend";

// Connects to data-module="nhsuk-header"
export default class extends Controller {
  connect() {
    return new Header(this.element);
  }
}
