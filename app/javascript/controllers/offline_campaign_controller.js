import { Controller } from "@hotwired/stimulus";
import { wb } from "../serviceworker-companion.js";

// Connects to data-controller="offline-campaign"
export default class extends Controller {
  connect() {}

  saveOffline() {
    var baseUrl = window.location.href;
    // console.log("baseUrl: ", baseUrl);

    console.log(
      "[Offline Campaign Controller saveOffline] saving campaign for offline"
    );
    wb.messageSW({
      type: "SAVE_CAMPAIGN_FOR_OFFLINE",
      payload: { campaignID: 1 },
    });

    // These end up cacheing something with a different "mode" and
    // "destination", which may be causing these not to work properly.
    // fetch(`${baseUrl}children/`);
    // fetch(`${baseUrl}children.json`);
    // fetch(`${baseUrl}children/show-template`);
  }
}
