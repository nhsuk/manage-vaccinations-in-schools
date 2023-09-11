import { Controller } from "@hotwired/stimulus";
import NhsukHeader from "nhsuk-frontend/packages/components/header/header";

// Connects to data-module="nhsuk-header"
export default class extends Controller {
  connect() {
    NhsukHeader();
  }
}
