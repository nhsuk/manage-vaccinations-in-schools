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

async function campaignShowTemplate(request) {
  let campaignId = parseCampaignIdFromURL(request.url);
  console.debug(
    "[Service Worker campaignChildrenVaccinationsHandlerCb]",
    `retrieving template ${campaignShowTemplateURL(campaignId)} from cache`
  );
  const cache = await caches.open(cacheNames.runtime);
  return await cache.match(campaignShowTemplateURL(campaignId));
}

async function lookupCachedResponse(request) {
  const cache = await caches.open(cacheNames.runtime);
  const response = await cache.match(request.url);

  return response;
}

async function campaignChildrenVaccinationsHandlerCb({ request }) {
  console.debug(
    "[Service Worker campaignChildrenVaccinationsHandlerCb] request: ",
    request
  );

  if (!checkOnlineStatus()) return await campaignShowTemplate(request);

  try {
    const response = await fetch(request);
    console.debug(
      `[Service Worker cacheResponse] fetch ${request.url} received response:`,
      response
    );
    return cacheResponse(request, response);
  } catch (err) {
    console.debug(
      "[Service Worker campaignChildrenVaccinationsHandlerCb]",
      `fetch ${request.url} did not receive response for request`,
      err
    );
    return await campaignShowTemplate(request);
  }
}

const defaultHandlerCB = async ({ request }) => {
  console.debug("[Service Worker defaultHandlerCB] request:", request);

  if (!checkOnlineStatus()) {
    return lookupCachedResponse(request);
  }

  try {
    const response = await fetch(request);
    console.debug(
      "[Service Worker defaultHandlerCB] response:",
      response.clone()
    );

    return cacheResponse(request, response);
  } catch (err) {
    console.debug(
      "[Service Worker defaultHandlerCB] no response, we're offline:",
      err
    );

    return await lookupCachedResponse(request);
  }
};

console.debug("[Service Worker] registering routes");
setOnlineMode();
registerRoute(
  campaignChildrenVaccinationsRoute,
  campaignChildrenVaccinationsHandlerCb
);
setDefaultHandler(defaultHandlerCB);
