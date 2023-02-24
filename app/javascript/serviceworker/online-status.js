const REFRESH_INTERVAL = 5 * 1000;

let online = true;

export const setOfflineMode = () => (online = false);

export const setOnlineMode = () => (online = true);

export const toggleOnlineStatus = () => {
  return online ? setOfflineMode() : setOnlineMode();
};

export const isOnline = () => online;

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

export const fetchWithTimeout = async (resource, options = {}) => {
  const { timeout = 10000 } = options;
  delete options.timeout;

  const controller = new AbortController();
  const abortTimerId = setTimeout(() => controller.abort(), timeout);
  const response = await fetch(resource, {
    ...options,
    signal: controller.signal,
  });
  clearTimeout(abortTimerId);
  return response;
};

export const refreshOnlineStatus = async (cb) => {
  await sleep(REFRESH_INTERVAL);

  try {
    await fetchWithTimeout("/ping");

    await cb();
  } catch (err) {
    // Offline, do nothing
  }

  refreshOnlineStatus(cb);
};
