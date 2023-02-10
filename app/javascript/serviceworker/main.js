import { setDefaultHandler, registerRoute } from "workbox-routing";
import { checkOnlineStatus, toggleOnlineStatus } from "./online-status";
import { addAll, put, lookupCachedResponse, match } from "./cache";

const campaignChildrenVaccinationsRoute = new RegExp(
  "/campaigns/(\\d+)/children/(\\d+)$"
);

let messageHandlers = {
  TOGGLE_CONNECTION: (event) => {
    event.ports[0].postMessage(toggleOnlineStatus());
  },

  GET_CONNECTION_STATUS: (event) => {
    event.ports[0].postMessage(checkOnlineStatus());
  },

  SAVE_CAMPAIGN_FOR_OFFLINE: async ({ data }) => {
    const campaignId = data.payload["campaignId"];

    addAll([
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

async function campaignShowTemplate(request) {
  let campaignId = parseCampaignIdFromURL(request.url);
  console.debug(
    "[Service Worker campaignChildrenVaccinationsHandlerCb]",
    `retrieving template ${campaignShowTemplateURL(campaignId)} from cache`
  );
  return await match(campaignShowTemplateURL(campaignId));
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
    put(request, response.clone());
    return response;
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

    put(request, response.clone());
    return response;
  } catch (err) {
    console.debug(
      "[Service Worker defaultHandlerCB] no response, we're offline:",
      err
    );

    return await lookupCachedResponse(request);
  }
};

console.debug("[Service Worker] registering routes");
registerRoute(
  campaignChildrenVaccinationsRoute,
  campaignChildrenVaccinationsHandlerCb
);
setDefaultHandler(defaultHandlerCB);
