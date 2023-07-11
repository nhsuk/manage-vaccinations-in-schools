import { Controller } from "@hotwired/stimulus";
import { NotificationBanner } from "govuk-frontend";

// Connects to data-module="govuk-notification-banner"
export default class extends Controller {
  connect() {
    new NotificationBanner(this.element).init();
  }
}
