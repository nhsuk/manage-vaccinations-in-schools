import "@hotwired/turbo-rails";
import {
  createAll,
  isSupported,
  Button,
  Checkboxes,
  ErrorSummary,
  Header,
  NotificationBanner,
  SkipLink,
} from "nhsuk-frontend";

import { Autocomplete } from "./components/autocomplete.js";
import { UpgradedRadios as Radios } from "./components/radios.js";
import { Sticky } from "./components/sticky.js";
import { TimeoutWarning } from "./components/timeoutWarning.js";

// Configure Turbo
Turbo.session.drive = false;

/**
 * Check if component has been initialised
 *
 * @param {string} moduleName - Name of component module
 * @returns {boolean} Whether component is already initialised
 */
function isInitialised(moduleName) {
  return document.querySelector(`[data-${moduleName}-init]`) !== null;
}

/**
 * Initialise components
 *
 * We need to check if components have already been initialised because Turbo
 * may have initialised them on a previous page (pre-)load.
 */
function initialiseComponents() {
  if (!isSupported()) {
    document.body.classList.add("nhsuk-frontend-supported");
  }

  if (!isInitialised("app-autocomplete")) {
    createAll(Autocomplete);
  }

  if (!isInitialised("app-sticky")) {
    createAll(Sticky);
  }

  if (!isInitialised("nhsuk-button")) {
    createAll(Button, { preventDoubleClick: true });
  }

  if (!isInitialised("nhsuk-checkboxes")) {
    createAll(Checkboxes);
  }

  if (!isInitialised("nhsuk-error-summary")) {
    createAll(ErrorSummary);
  }

  if (!isInitialised("nhsuk-header")) {
    createAll(Header);
  }

  if (!isInitialised("nhsuk-radios")) {
    createAll(Radios);
  }

  if (!isInitialised("nhsuk-notification-banner")) {
    createAll(NotificationBanner);
  }

  if (!isInitialised("nhsuk-skip-link")) {
    createAll(SkipLink);
  }

  if (!isInitialised("app-timeout-warning")) {
    createAll(TimeoutWarning);
  }
}

// Initiate components once page has loaded
document.addEventListener("DOMContentLoaded", () => {
  initialiseComponents();
});

// Reinitialize components when Turbo loads (and preloads) a page
document.addEventListener("turbo:load", () => {
  initialiseComponents();
});

// Reinitialize components when Turbo morphs a page
document.addEventListener("turbo:morph", () => {
  initialiseComponents();
});
