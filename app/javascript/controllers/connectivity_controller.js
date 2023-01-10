import { Controller } from "@hotwired/stimulus";
import { Workbox } from "workbox-window";
import { wb } from "../serviceworker-companion.js";

// Connects to data-controller="offline"
export default class extends Controller {
  static targets = [ "status" ]

  connect() {
    console.log("Current status: ", this.status);
  }

  get status() {
    return this.statusTarget.textContent;
  }

  set status(text) {
    this.statusTarget.textContent = text;
  }

  async toggleConnection() {
    let offlineStatus = await wb.messageSW({type: 'TOGGLE_CONNECTION'});
    this.status = offlineStatus ? "Offline" : "Online";
  }
}
