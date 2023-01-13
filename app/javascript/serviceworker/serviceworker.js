import { CacheOnly, NetworkFirst } from 'workbox-strategies';
import { setDefaultHandler } from 'workbox-routing';

let connectionStatus = true;

function setOfflineMode() {
  console.debug("[Service Worker] setting connection to offline");
  setDefaultHandler(new CacheOnly());
}

function setOnlineMode() {
  console.debug("[Service Worker] setting connection to online");
  setDefaultHandler(new NetworkFirst());
}

let messageHandlers = {
  'TOGGLE_CONNECTION': (event) => {
    console.debug("[Service Worker] TOGGLE_CONNECTION set connection status to:", connectionStatus);
    connectionStatus = !connectionStatus;

    if (connectionStatus) {
      setOnlineMode();
    } else {
      setOfflineMode();
    }

    event.ports[0].postMessage(connectionStatus);
  },

  'GET_CONNECTION_STATUS': (event) => {
    console.debug("[Service Worker] GET_CONNECTION_STATUS Returning status:", connectionStatus);
    event.ports[0].postMessage(connectionStatus);
  }
}

self.addEventListener('message', (event) => {
  if (event.data && event.data.type) {
    messageHandlers[event.data.type](event);
  }
});

setOnlineMode();
