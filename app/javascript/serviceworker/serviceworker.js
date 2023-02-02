import { CacheOnly, NetworkFirst } from "workbox-strategies";
import { setDefaultHandler, registerRoute } from "workbox-routing";
import { cacheNames } from "workbox-core";

let connectionStatus = true;

const campaignChildrenVaccinationsRoute = new RegExp(
  "/campaigns/(\\d+)/children/(\\d+)$"
);

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

  SAVE_CAMPAIGN_FOR_OFFLINE: ({ data }) => {
    console.debug(
      "[Service Worker SAVE_CAMPAIGN_FOR_OFFLINE] saving campaign for offline:",
      data
    );

    const campaignID = data.payload["campaignID"];

    caches
      .open(cacheNames.runtime)
      .then((cache) => {
        console.debug(
          "[Service Worker SAVE_CAMPAIGN_FOR_OFFLINE]",
          "Caching campaign pages in cache:",
          cacheNames.runtime,
          cache
        );

        cache.addAll([
          `/campaigns/${campaignID}/children`,
          `/campaigns/${campaignID}/children.json`,
          `/campaigns/${campaignID}/children/show-template`,
        ]);
      })
      .catch((err) => {
        console.error(
          "[Service Worker SAVE_CAMPAIGN_FOR_OFFLINE]",
          "Could not open cache",
          cacheNames.runtime,
          err
        );
      });
  },
};

self.addEventListener("message", (event) => {
  if (event.data && event.data.type) {
    messageHandlers[event.data.type](event);
  }
});

function parseCampaignIDFromURL(url) {
  let match = url.match("/campaigns/(\\d+)/");
  if (match) {
    return match[1];
  } else {
    return null;
  }
}

function campaignShowTemplateURL(campaignID) {
  return `http://localhost:3000/campaigns/${campaignID}/children/show-template`;
}

const campaignChildrenVaccinationsHandlerCB = async ({ request, event }) => {
  console.debug(
    "[Service Worker campaignChildrenVaccinationsHandlerCB]",
    "handling request: ",
    request
  );

  return fetch(event.request)
    .then((response) => {
      console.debug(
        "[Service Worker campaignChildrenVaccinationsHandlerCB]",
        `fetch ${request.url} received response:`,
        response
      );

      caches
        .open(cacheNames.runtime)
        .then((cache) => {
          cache.put(event.request, response.clone());
        })
        .catch((err) => {
          console.error(
            "[Service Worker campaignChildrenVaccinationsHandlerCB]",
            `error cacheing ${event.request.url} to ${cacheNames.runtime}:`,
            err
          );
        });

      return response;
    })
    .catch((err) => {
      console.debug(
        "[Service Worker campaignChildrenVaccinationsHandlerCB]",
        `fetch ${request.url} did not receive response for request`,
        err
      );

      let campaignID = parseCampaignIDFromURL(request.url);
      console.debug(
        "[Service Worker campaignChildrenVaccinationsHandlerCB]",
        `retrieving template ${campaignShowTemplateURL(campaignID)} from cache`
      );

      return caches
        .open(cacheNames.runtime)
        .then((cache) => {
          let cacheResponse = cache.match(campaignShowTemplateURL(campaignID));

          return cacheResponse;
        })
        .catch((err) => {
          console.error(
            "[Service Worker campaignChildrenVaccinationsHandlerCB]",
            `error retrieving ${campaignShowTemplateURL(
              campaignID
            )} from cache ${cacheNames.runtime}:`,
            err
          );
        });
    });
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
