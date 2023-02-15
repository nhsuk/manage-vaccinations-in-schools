import { setDefaultHandler, registerRoute } from "workbox-routing";
import { checkOnlineStatus } from "./online-status";
import { put, match } from "./cache";
import { handler as messageHandler } from "./messages";
import { childRoute, childRouteHandler } from "./child-route";
import { recordRoute, recordRouteHandler } from "./record-route";

const defaultHandlerCB = async ({ request }) => {
  console.debug("[Service Worker defaultHandlerCB] request:", request);

  if (!checkOnlineStatus()) {
    return await match(request.url);
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

    return await match(request.url);
  }
};

self.addEventListener("message", messageHandler);
console.debug("[Service Worker] registering routes");
registerRoute(childRoute, childRouteHandler);
registerRoute(recordRoute, recordRouteHandler, "POST");
setDefaultHandler(defaultHandlerCB);
