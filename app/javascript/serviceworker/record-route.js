import { checkOnlineStatus } from "./online-status";
import { match } from "./cache";

const getCampaignIdFromURL = (url) => url.match("/campaigns/(\\d+)/")[1];

const campaignShowTemplateURL = (campaignId) =>
  `http://localhost:3000/campaigns/${campaignId}/children/record-template`;

export const recordRoute = new RegExp(
  "/campaigns/(\\d+)/children/(\\d+)/record$"
);

export const recordRouteHandler = async ({ request }) => {
  try {
    if (!checkOnlineStatus()) throw new NetworkError("Offline");

    var response = await fetch(request, { method: "POST" });
  } catch (err) {
    const campaignId = getCampaignIdFromURL(request.url);
    const campaignUrl = campaignShowTemplateURL(campaignId);

    // TODO: Cache request for later.

    var response = await match(campaignUrl);
  }

  return response;
};
