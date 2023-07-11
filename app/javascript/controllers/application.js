import { Application, defaultSchema } from "@hotwired/stimulus";

const schema = {
  ...defaultSchema,
  controllerAttribute: "data-module",
};

const application = Application.start(document.documentElement, schema);

// Configure Stimulus development experience
application.debug = false;
window.Stimulus = application;

export { application };
