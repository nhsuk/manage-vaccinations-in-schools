import { Workbox } from "workbox-window";

export let wb;

const keepServiceWorkerAlive = () => {
  setInterval(() => {
    wb.messageSW({
      type: "GET_CONNECTION_STATUS",
    });
  }, 20 * 1000);
};

export function initServiceWorker() {
  if ("serviceWorker" in navigator) {
    wb = new Workbox("/sw.js");
    wb.register();

    keepServiceWorkerAlive();
  }
}
