import { CacheOnly, NetworkFirst } from "workbox-strategies";
import { setDefaultHandler, registerRoute } from "workbox-routing";
import { cacheNames } from "workbox-core";

let connectionStatus = true;

const campaignChildrenVaccinationsRoute = new RegExp(
  "/campaigns/(\\d+)/children/(\\d+)$"
);

function setOfflineMode() {
  setDefaultHandler(new CacheOnly());
}

function setOnlineMode() {
  setDefaultHandler(new NetworkFirst());
}

let messageHandlers = {
  TOGGLE_CONNECTION: (event) => {
    console.debug(
      "[Service Worker TOGGLE_CONNECTION] set connection status to:",
      !connectionStatus
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
      "[Service Worker GET_CONNECTION_STATUS] returning status:",
      connectionStatus
    );
    event.ports[0].postMessage(connectionStatus);
  },

  SAVE_CAMPAIGN_FOR_OFFLINE: async ({ data }) => {
    const campaignId = data.payload["campaignId"];

    const cache = await caches.open(cacheNames.runtime);
    await cache.addAll([
      `/campaigns/${campaignId}/children`,
      `/campaigns/${campaignId}/children.json`,
      `/campaigns/${campaignId}/children/show-template`,
    ]);
  },
};

self.addEventListener("message", (event) => {
  if (event.data && event.data.type) {
    console.debug(
      "[Service Worker Message Listener] received message event:",
      event.data
    );
    messageHandlers[event.data.type](event);
  }
});

function parseCampaignIdFromURL(url) {
  const [_, campaignId] = url.match("/campaigns/(\\d+)/");
  return campaignId;
}

function campaignShowTemplateURL(campaignID) {
  return `http://localhost:3000/campaigns/${campaignID}/children/show-template`;
}

const campaignChildrenVaccinationsHandlerCB = async ({ request, event }) => {
  const cache = await caches.open(cacheNames.runtime);

  try {
    const response = await fetch(event.request);
    cache.put(event.request, response.clone());

    return response;
  } catch (err) {
    const campaignId = parseCampaignIdFromURL(request.url);

    return cache.match(campaignShowTemplateURL(campaignId));
  }
};

const defaultHandlerCB = async ({ request }) => {
  console.log("[Service Worker defaultHandlerCB] request: ", request);

  return fetch(request)
    .then((response) => {
      caches
        .open(cacheNames.runtime)
        .then((cache) => {
          cache.put(request, response.clone());
        })
        .catch((err) => {
          console.log(
            "[Service Worker defaultHandlerCB] could not open cache:",
            err
          );
        });
      return response.clone();
    })
    .catch(async (err) => {
      console.log(
        "[Service Worker defaultHandlerCB] no response, we're offline:",
        err
      );

      var response = await caches.open(cacheNames.runtime).then((cache) => {
        return cache.match(request.url);
      });

      if (response) {
        console.log(
          "[Service Worker defaultHandlerCB] cached response: ",
          response
        );
      } else {
        console.log("[Service Worker defaultHandlerCB] no cached response :(");
      }
      return response;
    });
};

console.log("[Service Worker] registering routes");
setOnlineMode();
registerRoute(
  campaignChildrenVaccinationsRoute,
  campaignChildrenVaccinationsHandlerCB
);
setDefaultHandler(defaultHandlerCB);
