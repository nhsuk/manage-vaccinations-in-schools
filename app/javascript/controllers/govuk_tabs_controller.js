import { Controller } from "@hotwired/stimulus";
import { Tabs } from "govuk-frontend";

// Connects to data-module="govuk-tabs"
export default class extends Controller {
  connect() {
    new Tabs(this.element).init();
  }
}
