import { isOnline } from "./online-status";
import { put, match } from "./cache";

const getCampaignIdFromURL = (url) => url.match("/sessions/(\\d+)/")[1];

const programmeShowTemplateURL = (programmeId) =>
  `/sessions/${programmeId}/vaccinations/show-template`;

export const childRoute = new RegExp("/sessions/(\\d+)/vaccinations/(\\d+)$");

export const childRouteHandler = async ({ request }) => {
  try {
    if (!isOnline()) throw new NetworkError("Offline");

    var response = await fetch(request);
    put(request, response.clone());
  } catch (err) {
    const programmeId = getCampaignIdFromURL(request.url);
    const programmeUrl = programmeShowTemplateURL(programmeId);

    var response = await match(programmeUrl);
  }

  return response;
};
