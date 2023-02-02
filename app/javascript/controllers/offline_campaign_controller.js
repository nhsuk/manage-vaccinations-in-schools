import { Controller } from "@hotwired/stimulus";
import { wb } from "../serviceworker-companion.js";

// Connects to data-controller="offline-campaign"
export default class extends Controller {
  connect() {}

  saveOffline() {
    console.log(
      "[Offline Campaign Controller saveOffline] saving campaign for offline"
    );
    wb.messageSW({
      type: "SAVE_CAMPAIGN_FOR_OFFLINE",
      payload: { campaignID: 1 },
    });
  }
}
