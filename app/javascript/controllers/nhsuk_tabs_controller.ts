import { Controller } from "@hotwired/stimulus";
import NhsukTabs from "nhsuk-frontend/packages/components/tabs/tabs";

// Connects to data-module="nhsuk-tabs"
export default class extends Controller {
  connect() {
    NhsukTabs();
  }
}
