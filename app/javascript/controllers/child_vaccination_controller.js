import { Controller } from "@hotwired/stimulus";

function parseIDsFromURL(url) {
  var match = url.match("/campaigns/(\\d+)/children/(\\d+)$");
  if (match) {
    return { campaignID: match[1], childID: match[2] };
  } else {
    return {};
  }
}

// Connects to data-controller="child-vaccination"
export default class extends Controller {
  static targets = [
    "fullName",
    "sex",
    "dob",
    "consent",
    "gp",
    "nhsNumber",
    "screening",
  ];

  async initialize() {
    var { campaignID, childID } = parseIDsFromURL(window.location.href);
    var url = `/campaigns/${campaignID}/children.json`;
    this.childVaccination = fetch(url).then((response) => {
      return response.json().then((json) => {
        return json[childID];
      });
    });
  }

  connect() {
    this.childVaccination.then((data) => {
      this.fullNameTarget.textContent = data["full_name"];
      this.sexTarget.textContent = data["sex"];
      this.dobTarget.textContent = data["dob"];
      this.consentTarget.textContent = data["consent"];
      this.gpTarget.textContent = data["gp"];
      this.nhsNumberTarget.textContent = data["nhs_number"];
      this.screeningTarget.textContent = data["screening"];
    });
  }
}
