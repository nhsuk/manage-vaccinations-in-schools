import { Controller } from "@hotwired/stimulus";
import { Workbox } from "workbox-window";
import { wb } from "../serviceworker-companion.js";

// Connects to data-controller="offline"
export default class extends Controller {
  static targets = ["status", "button", "banner"];

  async connect() {
    this.connectionStatus = await wb.messageSW({
      type: "GET_CONNECTION_STATUS",
    });
  }

  get status() {
    return this.statusTarget.textContent;
  }

  set status(text) {
    this.statusTarget.textContent = text;
  }

  get connectionStatus() {
    return this.connectionStatusValue;
  }

  set connectionStatus(st) {
    this.connectionStatusValue = st;
    if (st) {
      this.status = "Online";
      this.buttonTarget.textContent = "Go Offline";
      this.bannerTarget.style.display = "none";
    } else {
      this.status = "Offline";
      this.buttonTarget.textContent = "Go Online";
      this.bannerTarget.style.display = "inherit";
    }
  }

  async toggleConnection() {
    this.connectionStatus = await wb.messageSW({ type: "TOGGLE_CONNECTION" });
  }
}
