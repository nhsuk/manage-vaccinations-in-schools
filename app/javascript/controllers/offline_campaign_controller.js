import { Controller } from "@hotwired/stimulus";
import { wb } from "../serviceworker-companion.js";

// Connects to data-controller="offline-campaign"
export default class extends Controller {
  connect() {}

  saveOffline() {
    // Pass in paths to CSS and JS to save for offline use, because document
    // methods are not available in serviceWorker
    const css = document.querySelector("link[rel=stylesheet]").href;
    const js = document.querySelector("script[src]").src;

    wb.messageSW({
      type: "SAVE_CAMPAIGN_FOR_OFFLINE",
      payload: { campaignId: 1, additionalItems: [css, js] },
    });
  }
}
