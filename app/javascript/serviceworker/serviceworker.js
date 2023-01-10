import { CacheOnly, NetworkFirst } from 'workbox-strategies';
import { setDefaultHandler } from 'workbox-routing';

let offlineMode = false;

function setOfflineMode() {
  setDefaultHandler(new CacheOnly());
}

function setOnlineMode() {
  setDefaultHandler(new NetworkFirst());
}

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'TOGGLE_CONNECTION') {

    offlineMode = !offlineMode;
    if (offlineMode) {
      setOfflineMode();
    } else {
      setOnlineMode();
    }

    event.ports[0].postMessage(offlineMode)
  }
});

setOnlineMode();
