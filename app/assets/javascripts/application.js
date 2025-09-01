import "@hotwired/turbo-rails";
import {
  createAll,
  Button,
  Checkboxes,
  ErrorSummary,
  Header,
  NotificationBanner,
  SkipLink,
} from "nhsuk-frontend";

import { Autocomplete } from "./components/autocomplete.js";
import { UpgradedRadios as Radios } from "./components/radios.js";

// Configure Turbo
Turbo.session.drive = false;

// Initiate NHS.UK frontend components on page load
document.addEventListener("DOMContentLoaded", () => {
  createAll(Autocomplete);
  createAll(Button, { preventDoubleClick: true });
  createAll(Checkboxes);
  createAll(ErrorSummary);
  createAll(Header);
  createAll(Radios);
  createAll(NotificationBanner);
  createAll(SkipLink);
});
