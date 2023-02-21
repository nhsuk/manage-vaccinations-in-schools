const REFRESH_INTERVAL = 5 * 1000;

let online = true;

export const setOfflineMode = () => (online = false);

export const setOnlineMode = () => (online = true);

export const toggleOnlineStatus = () => {
  return online ? setOfflineMode() : setOnlineMode();
};

export const isOnline = () => online;

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

export const refreshOnlineStatus = async (cb) => {
  await sleep(REFRESH_INTERVAL);

  try {
    await fetch("/health");

    await cb();
  } catch (err) {
    // Offline, do nothing
  }

  refreshOnlineStatus(cb);
};
