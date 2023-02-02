import { setDefaultHandler, registerRoute } from "workbox-routing";
import { cacheNames } from "workbox-core";

let onlineStatus = true;

const campaignChildrenVaccinationsRoute = new RegExp(
  "/campaigns/(\\d+)/children/(\\d+)$"
);

function setOfflineMode() {
  console.debug("[Service Worker] setting connection to offline");
}

function setOnlineMode() {
  console.debug("[Service Worker] setting connection to online");
}

function checkOnlineStatus() {
  return onlineStatus;
}

let messageHandlers = {
  TOGGLE_CONNECTION: (event) => {
    console.debug(
      "[Service Worker TOGGLE_CONNECTION] set connection status to:",
      !onlineStatus
    );
    onlineStatus = !onlineStatus;

    if (onlineStatus) {
      setOnlineMode();
    } else {
      setOfflineMode();
    }

    event.ports[0].postMessage(onlineStatus);
  },

  GET_CONNECTION_STATUS: (event) => {
    console.debug(
      "[Service Worker GET_CONNECTION_STATUS] returning status:",
      onlineStatus
    );
    event.ports[0].postMessage(onlineStatus);
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

function cacheResponse(request, response) {
  caches.open(cacheNames.runtime).then((cache) => {
    cache.put(request, response);
  });

  return response.clone();
}

function campaignShowTemplate(request) {
  let campaignID = parseCampaignIdFromURL(request.url);
  console.debug(
    "[Service Worker campaignChildrenVaccinationsHandlerCB]",
    `retrieving template ${campaignShowTemplateURL(campaignID)} from cache`
  );

  return caches
    .open(cacheNames.runtime)
    .then((cache) => {
      let response = cache.match(campaignShowTemplateURL(campaignID));

      return response;
    })
    .catch((err) => {
      console.error(
        "[Service Worker campaignChildrenVaccinationsHandlerCB]",
        `error retrieving ${campaignShowTemplateURL(campaignID)} from cache ${
          cacheNames.runtime
        }:`,
        err
      );
    });
}

async function lookupCachedResponse(request) {
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
  return response.clone();
}

async function campaignChildrenVaccinationsHandlerCB({ request }) {
  console.debug(
    "[Service Worker campaignChildrenVaccinationsHandlerCB] request: ",
    request
  );

  if (!checkOnlineStatus()) return campaignShowTemplate(request);

  try {
    const response = await fetch(request);
    console.debug(
      `[Service Worker cacheResponse] fetch ${request.url} received response:`,
      response
    );
    return cacheResponse(request, response);
  } catch (err) {
    console.debug(
      "[Service Worker campaignChildrenVaccinationsHandlerCB]",
      `fetch ${request.url} did not receive response for request`,
      err
    );
    return campaignShowTemplate(request);
  }
}

const defaultHandlerCB = async ({ request }) => {
  console.log("[Service Worker defaultHandlerCB] request: ", request);

  if (checkOnlineStatus()) {
    return fetch(request)
      .then((response) => {
        console.log(
          "[Service Worker defaultHandlerCB] response: ",
          response.clone()
        );

        return cacheResponse(request, response);
      })
      .catch(async (err) => {
        console.log(
          "[Service Worker defaultHandlerCB] no response, we're offline:",
          err
        );

        return lookupCachedResponse(request);
      });
  } else {
    return lookupCachedResponse(request);
  }
};

console.log("[Service Worker] registering routes");
setOnlineMode();
registerRoute(
  campaignChildrenVaccinationsRoute,
  campaignChildrenVaccinationsHandlerCB
);
setDefaultHandler(defaultHandlerCB);
