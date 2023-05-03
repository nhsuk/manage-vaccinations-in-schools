import { Controller } from "@hotwired/stimulus";
import { wb } from "../serviceworker-companion.js";

// Connects to data-controller="setup-offline"
export default class extends Controller {
  static targets = ["form", "password"];

  declare readonly formTarget: HTMLFormElement;
  declare readonly passwordTarget: HTMLInputElement;

  connect() {
    this.formTarget.addEventListener("submit", this.handleSubmit.bind(this));
  }

  async handleSubmit(event: Event) {
    event.preventDefault();

    // Pass in paths to CSS and JS to save for offline use, because document
    // methods are not available in serviceWorker
    const css = (
      document.querySelector("link[rel=stylesheet]") as HTMLLinkElement
    ).href;
    const js = (document.querySelector("script[src]") as HTMLScriptElement).src;

    await wb.messageSW({
      type: "SAVE_CAMPAIGN_FOR_OFFLINE",
      payload: {
        password: this.passwordTarget.value,
        campaignId: 1,
        additionalItems: [css, js],
      },
    });

    this.formTarget.submit();
  }
}
