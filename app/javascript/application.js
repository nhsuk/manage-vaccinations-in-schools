import { initAll } from "govuk-frontend";
import { initServiceWorker } from "./serviceworker-companion";
import "./controllers";


initAll();
initServiceWorker();
