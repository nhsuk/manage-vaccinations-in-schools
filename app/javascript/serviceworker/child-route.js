import { checkOnlineStatus } from "./online-status";
import { put, match } from "./cache";

const getCampaignIdFromURL = (url) => url.match("/campaigns/(\\d+)/")[1];

const campaignShowTemplateURL = (campaignId) =>
  `http://localhost:3000/campaigns/${campaignId}/children/show-template`;

export const childRoute = new RegExp("/campaigns/(\\d+)/children/(\\d+)$");

export const childRouteHandler = async ({ request }) => {
  const campaignId = getCampaignIdFromURL(request.url);
  const campaignUrl = campaignShowTemplateURL(campaignId);

  if (!checkOnlineStatus()) return await match(campaignUrl);

  try {
    const response = await fetch(request);
    put(request, response.clone());
    return response;
  } catch (err) {
    return await match(campaignUrl);
  }
};
