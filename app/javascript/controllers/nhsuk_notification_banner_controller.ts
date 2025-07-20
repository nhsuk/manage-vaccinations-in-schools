import { Controller } from "@hotwired/stimulus";
import { NotificationBanner } from "nhsuk-frontend";

// Connects to data-module="nhsuk-notification-banner"
export default class extends Controller {
  connect() {
    new NotificationBanner(this.element);
  }
}
