import { init as initCache, addAll } from "./cache";

const getCampaignIdFromURL = (url: string) =>
  url.match("/campaigns/(\\d+)/")[1];

export const setupOfflineRoute = new RegExp("/campaigns/(\\d+)/setup-offline$");

export const setupOfflineRouteHandler = async ({ request }) => {
  const clonedRequest = request.clone();
  const response = await fetch(request, { method: "POST" });
  const success = response.type === "opaqueredirect";

  if (success) {
    const formData = Object.fromEntries(await clonedRequest.formData());
    const css = formData["offline_password[assets_css]"];
    const js = formData["offline_password[assets_js]"];
    const password = formData["offline_password[password]"];

    await initCache(password);

    const campaignId = getCampaignIdFromURL(request.url);
    await addAll([
      css,
      js,
      `/favicon.ico`,
      `/dashboard`,
      `/campaigns/${campaignId}`,
      `/campaigns/${campaignId}/children`,
      `/campaigns/${campaignId}/children.json`,
      `/campaigns/${campaignId}/children/record-template`,
      `/campaigns/${campaignId}/children/show-template`,
    ]);
  }

  return response;
};
