import { Workbox } from "workbox-window";

export let wb;

export function initServiceWorker() {
  if ("serviceWorker" in navigator) {
    wb = new Workbox("/serviceworker.js");
    console.log("[ServiceWorker Companion] registering service worker: ", wb);

    wb.addEventListener("activated", (event) => {
      console.log("[Service Worker Companion] service worker activated", event);
    });

    wb.addEventListener("waiting", (event) => {
      console.log(
        "[Service Worker Companion] service worker is waiting for current version to be fully unloaded",
        event
      );
    });

    wb.addEventListener("controlling", (event) => {
      console.log(
        "[Service Worker Companion] service worker is IN CONTROL",
        event
      );
    });

    wb.addEventListener("installed", (event) => {
      console.log("[Service Worker Companion] service worker installed", event);
    });

    wb.register();
  }
}
