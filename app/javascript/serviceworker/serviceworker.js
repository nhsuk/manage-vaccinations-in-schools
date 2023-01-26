import { CacheOnly, NetworkFirst } from "workbox-strategies";
import { setDefaultHandler, registerRoute } from "workbox-routing";
import { getOrCreateDefaultRouter } from "workbox-routing/utils/getOrCreateDefaultRouter.js";

let connectionStatus = true;

const childrenShowRoute = new RegExp("/campaigns/(\\d+)/children/(\\d+)$");

function setOfflineMode() {
  console.debug("[Service Worker] setting connection to offline");
  setDefaultHandler(new CacheOnly());
}

function setOnlineMode() {
  console.debug("[Service Worker] setting connection to online");
  setDefaultHandler(new NetworkFirst());
}

let messageHandlers = {
  TOGGLE_CONNECTION: (event) => {
    console.debug(
      "[Service Worker] TOGGLE_CONNECTION set connection status to:",
      connectionStatus
    );
    connectionStatus = !connectionStatus;

    if (connectionStatus) {
      setOnlineMode();
    } else {
      setOfflineMode();
    }

    event.ports[0].postMessage(connectionStatus);
  },

  GET_CONNECTION_STATUS: (event) => {
    console.debug(
      "[Service Worker] GET_CONNECTION_STATUS Returning status:",
      connectionStatus
    );
    event.ports[0].postMessage(connectionStatus);
  },
};

self.addEventListener("message", (event) => {
  if (event.data && event.data.type) {
    messageHandlers[event.data.type](event);
  }
});

const childrenShowHandlerCb = async ({ url, request, event, params }) => {
  if (connectionStatus) {
    event.respondWith(new NetworkFirst().handle({ event, request }));
  } else {
    let newRequest = new Request(
      `/campaigns/${params[0]}/children/show_template`
    );
    let handler = new NetworkFirst().handle({
      event,
      params,
      request: newRequest,
    });
    console.log(
      "[Service Worker childrenShowHandlerCb] retrieving child show template"
    );
    event.respondWith(handler);
  }
};

registerRoute(childrenShowRoute, childrenShowHandlerCb);
setOnlineMode();
