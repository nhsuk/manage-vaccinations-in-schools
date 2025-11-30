import { Component } from "nhsuk-frontend";
import { get, post } from "../helpers/fetch";

const TIME_REMAINING_ENDPOINT = "/users/sessions/time-remaining";
const REFRESH_SESSION_ENDPOINT = "/users/sessions/refresh";
const SHOW_WARNING_AT_MS = 120_000;

/**
 * TimeoutWarning component
 *
 * @augments Component<HTMLDialogElement>
 *
 * @param {HTMLDialogElement | null} $root - HTML dialog element to use for component
 */
export class TimeoutWarning extends Component {
  static elementType = HTMLDialogElement;

  /**
   * Name for the component used when initialising using data-module attributes
   */
  static moduleName = "app-timeout-warning";

  logoutAt = null;

  /**
   * @param {HTMLDialogElement | null} $root - HTML dialog element to use for component
   */
  constructor($root) {
    super($root);

    if ((!$root) instanceof HTMLDialogElement) {
      throw new Error(
        "TimeoutWarning component must be used on a dialog element",
      );
    }

    this.fetchTimeRemaining = this.fetchTimeRemaining.bind(this);
    this.toggleModalVisibility = this.toggleModalVisibility.bind(this);
    this.updateTimerElements = this.updateTimerElements.bind(this);

    this.instanceId = crypto.randomUUID();

    this.getElements($root);
    this.subscribeToSessionRefresh();
    this.addEventListeners();
    this.startTimeoutMonitoring();
  }

  /**
   * Get the elements of the component
   *
   * @param {HTMLDialogElement} $root - HTML dialog element to use for component
   */
  getElements($root) {
    this.dialogElement = $root;
    this.button = this.dialogElement.querySelector("button");
    this.timerElement = this.dialogElement.querySelector(
      "#app-timeout-warning-timer",
    );
    this.timerElementAccessible = this.dialogElement.querySelector(
      "#app-timeout-warning-timer-accessible",
    );
  }

  /**
   * Subscribe to the session refresh broadcast channel to be notified when
   * the session is refreshed in another tab or window
   */
  subscribeToSessionRefresh() {
    if (!window.BroadcastChannel) return;
    this.channel = new BroadcastChannel("mavis.timeout-warning.refresh");
    this.channel.onmessage = (event) => {
      // Ignore messages sent by this TimeoutWarning instance
      if (event.data.instanceId === this.instanceId) return;
      this.fetchTimeRemaining();
    };
    // Send message on initialisation to ensure the session time remaining
    // is up to date in any other tab or window
    this.sendSessionRefreshMessage();
  }

  addEventListeners() {
    this.button.addEventListener("click", () => {
      this.refreshSession();
      this.dialogElement.close();
    });
    // Esc will close the dialog (native dialog element behaviour) and refresh the session
    this.dialogElement.addEventListener("keydown", (event) => {
      if (event.key === "Escape") {
        this.refreshSession();
      }
    });
  }

  startTimeoutMonitoring() {
    this.fetchTimeRemaining();
    // Offset the interval from 60 seconds to avoid the check to sync
    // clocks with the server lining up exactly with the warning being shown
    setInterval(this.fetchTimeRemaining, 53000);
    setInterval(() => {
      this.toggleModalVisibility();
      this.triggerLogoutIfNeeded();
      this.updateTimerElements();
    }, 1000);
  }

  async fetchTimeRemaining() {
    const data = await get(TIME_REMAINING_ENDPOINT);
    this.updateLogoutAtWithSeconds(data.time_remaining_seconds);
  }

  async refreshSession() {
    this.logoutAt = null;
    const data = await post(REFRESH_SESSION_ENDPOINT, {});
    this.updateLogoutAtWithSeconds(data.time_remaining_seconds);
    this.sendSessionRefreshMessage();
  }

  sendSessionRefreshMessage() {
    if (this.channel) {
      this.channel.postMessage({
        instanceId: this.instanceId,
      });
    }
  }

  /**
   * Update the logout time with the number of seconds remaining
   *
   * @param {number} timeRemainingSeconds - Number of seconds remaining
   */
  updateLogoutAtWithSeconds(timeRemainingSeconds) {
    this.logoutAt = Date.now() + timeRemainingSeconds * 1000;
  }

  triggerLogoutIfNeeded() {
    if (this.logoutAt === null) return;
    if (Date.now() >= this.logoutAt) {
      // Add a small delay to ensure the session has ended in the server
      setTimeout(() => {
        this.fetchTimeRemaining();
      }, 1000);
    }
  }

  /**
   * Show or hide the modal based on whether the warning time
   * has been reached or not
   */
  toggleModalVisibility() {
    if (this.showWarningAt() === null) return;

    if (Date.now() >= this.showWarningAt()) {
      if (this.dialogElement.open) return;
      this.dialogElement.showModal();
    } else {
      if (this.dialogElement.open) {
        this.dialogElement.close();
      }
    }
  }

  /**
   * Calculate the time at which the warning should be shown
   *
   * @returns {number | null} Time at which the warning should be shown, or null if no warning should be shown
   */
  showWarningAt() {
    if (this.logoutAt === null) return null;
    return this.logoutAt - SHOW_WARNING_AT_MS;
  }

  /**
   * Update the timer elements with the time remaining.
   *
   * The visible timer element is updated every second,
   * the accessible timer element is updated every 15 seconds.
   */
  updateTimerElements() {
    let timeRemainingSeconds = Math.floor((this.logoutAt - Date.now()) / 1000);
    if (timeRemainingSeconds < 0) {
      timeRemainingSeconds = 0;
    }
    this.timerElement.textContent =
      TimeoutWarning.formatTimeRemaining(timeRemainingSeconds);
    if (timeRemainingSeconds % 15 === 0) {
      this.timerElementAccessible.textContent =
        TimeoutWarning.formatTimeRemaining(timeRemainingSeconds);
    }
  }

  /**
   * Format the time remaining as a string with minutes and seconds
   *
   * @param {number} timeRemainingSeconds - Number of seconds remaining
   * @returns {string} Formatted time remaining
   */
  static formatTimeRemaining(timeRemainingSeconds) {
    const minutes = Math.floor(timeRemainingSeconds / 60);
    const seconds = timeRemainingSeconds % 60;
    // Only show minutes if there's more than 1 minute remaining
    let result = `${seconds} second${seconds === 1 ? "" : "s"}`;
    if (minutes > 0) {
      result = `${minutes} minute${minutes > 1 ? "s" : ""} and ${result}`;
    }
    return result;
  }
}
