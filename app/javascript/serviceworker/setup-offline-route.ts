import { init as initCache, addAll } from "./cache";

const getCampaignIdFromURL = (url: string) => url.match("/sessions/(\\d+)/")[1];

export const setupOfflineRoute = new RegExp("/sessions/(\\d+)/setup-offline$");

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

    const programmeId = getCampaignIdFromURL(request.url);
    await addAll([
      css,
      js,
      `/favicon.ico`,
      `/start`,
      `/dashboard`,
      `/sessions/${programmeId}`,
      `/sessions/${programmeId}/vaccinations`,
      `/sessions/${programmeId}/vaccinations.json`,
      `/sessions/${programmeId}/vaccinations/record-template`,
      `/sessions/${programmeId}/vaccinations/show-template`,
    ]);
  }

  return response;
};
