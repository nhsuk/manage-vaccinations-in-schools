import {
  createAll,
  Button,
  Checkboxes,
  ErrorSummary,
  Radios,
  SkipLink,
} from "nhsuk-frontend";

import { Autocomplete } from "./components/autocomplete.js";

// Initiate NHS.UK frontend components on page load
document.addEventListener("DOMContentLoaded", () => {
  createAll(Autocomplete);
  createAll(Button, { preventDoubleClick: true });
  createAll(Checkboxes);
  createAll(ErrorSummary);
  createAll(Radios);
  createAll(SkipLink);
});
