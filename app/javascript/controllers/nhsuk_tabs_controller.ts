import { Controller } from "@hotwired/stimulus";
import { Tabs } from "nhsuk-frontend";

// Connects to data-module="nhsuk-tabs"
export default class extends Controller {
  connect() {
    return new Tabs(this.element);
  }
}
