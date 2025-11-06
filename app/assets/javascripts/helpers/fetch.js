function checkResponseStatus(response) {
  // Reload the page if the user is not authenticated
  // to trigger a server side redirect to the start page
  if (response.status === 401 || response.status === 403) {
    window.location.href = `${window.location.origin}${window.location.pathname}?timeout`;
  }
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}`);
  }
  if (response.status === 204 || response.status === 205) {
    throw new Error("No content received from endpoint");
  }
}

export async function get(url) {
  const data = await fetch(url, {
    headers: { Accept: "application/json" },
  }).then((response) => {
    checkResponseStatus(response);
    return response.json();
  });
  if (typeof data === "undefined")
    throw new Error("Failed to parse JSON response");
  return data;
}

export async function post(url, body) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
  const data = await fetch(url, {
    method: "post",
    headers: { Accept: "application/json", "X-CSRF-Token": csrfToken },
    credentials: "same-origin",
    body: JSON.stringify(body),
  }).then((response) => {
    checkResponseStatus(response);
    return response.json();
  });
  if (typeof data === "undefined")
    throw new Error("Failed to parse JSON response");
  return data;
}
