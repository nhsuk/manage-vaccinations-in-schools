import { Workbox } from "workbox-window";

export let wb;

export function initServiceWorker() {
  if ("serviceWorker" in navigator) {
    wb = new Workbox("/sw.js");
    wb.register();
  }
}
