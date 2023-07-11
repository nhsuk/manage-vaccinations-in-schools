import { Controller } from "@hotwired/stimulus";
import { wb } from "../serviceworker-companion.js";

// Connects to data-controller="offline"
export default class extends Controller {
  static targets = ["status", "button", "banner"];

  async connect() {
    console.log("[Connectivity Controller] requesting connection status");
    try {
      var timeoutFn = setTimeout(() => {
        console.log("[Connectivity Controller] SW never came back!!!");
      }, 10000);
      this.connectionStatus = await wb.messageSW({
        type: "GET_CONNECTION_STATUS",
      });
      clearTimeout(timeoutFn);
      console.log(
        `[Connectivity Controller] got connection status: ${this.connectionStatus}`,
      );
    } catch (err) {
      console.error(
        "[Connectivity Controller] got error sending GET_CONNECTION_STATUS ",
        "message to service worker:",
        err,
      );
    }
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
      console.log(
        "[Connectivity Controller] setting connection status to online",
      );
      this.status = "Online";
      this.buttonTarget.textContent = "Go offline";
      this.bannerTarget.style.display = "none";
    } else {
      console.log(
        "[Connectivity Controller] setting connection status to offline",
      );
      this.status = "Offline";
      this.buttonTarget.textContent = "Go online";
      this.bannerTarget.style.display = "inherit";
    }
  }

  async toggleConnection() {
    console.log(
      "[Connectivity Controller] sending message to toggle connection",
    );
    this.connectionStatus = await wb.messageSW({ type: "TOGGLE_CONNECTION" });
  }
}
