const REFRESH_INTERVAL = 5 * 1000;

let online = true;

export const setOfflineMode = () => (online = false);

export const setOnlineMode = () => (online = true);

export const toggleOnlineStatus = () => {
  return online ? setOfflineMode() : setOnlineMode();
};

export const isOnline = () => online;

export const refreshOnlineStatus = (cb) => {
  setInterval(async () => {
    try {
      await fetch("/health");

      cb();
    } catch (err) {
      // Offline, do nothing
    }
  }, REFRESH_INTERVAL);
};
