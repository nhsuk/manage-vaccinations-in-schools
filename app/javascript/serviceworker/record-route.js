import { isOnline } from "./online-status";
import { match } from "./cache";
import { add } from "./store";

const getCampaignIdFromURL = (url) => url.match("/sessions/(\\d+)/")[1];

const recordTemplateURL = (campaignId) =>
  `/sessions/${campaignId}/vaccinations/record-template`;

export const recordRoute = new RegExp(
  "/sessions/(\\d+)/vaccinations/(\\d+)/record$",
);

export const recordRouteHandler = async ({ request }) => {
  const clonedRequest = request.clone();
  const data = Object.fromEntries(await request.formData());

  try {
    if (!isOnline()) throw new NetworkError("Offline");

    var response = await fetch(clonedRequest, { method: "POST" });
  } catch (err) {
    const campaignId = getCampaignIdFromURL(request.url);
    const campaignUrl = recordTemplateURL(campaignId);

    add("delayedRequests", clonedRequest.url, data);

    var response = await match(campaignUrl);
  }

  return response;
};
