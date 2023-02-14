import { Controller } from "@hotwired/stimulus";
import { wb } from "../serviceworker-companion.js";

const getCampaignIdFromURL = (url) => url.match("/campaigns/(\\d+)")[1];

// Connects to data-controller="offline-campaign"
export default class extends Controller {
  connect() {}

  saveOffline() {
    wb.messageSW({
      type: "SAVE_CAMPAIGN_FOR_OFFLINE",
      payload: { campaignId: getCampaignIdFromURL(window.location.href) },
    });
  }
}
