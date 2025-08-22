import { Controller } from "@hotwired/stimulus";
import { Tabs } from "nhsuk-frontend";

// Connects to data-module="nhsuk-tabs"
export default class extends Controller {
  connect() {
    new Tabs(this.element);
  }
}
