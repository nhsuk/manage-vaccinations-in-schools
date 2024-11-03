import encoding from "k6/encoding";
import http from "k6/http";
import { check, sleep } from "k6";
import { randomIntBetween } from "https://jslib.k6.io/k6-utils/1.2.0/index.js";

// Required environment variables
const BASE_URL = __ENV.BASE_URL;
const SESSION_SLUG = __ENV.SESSION_SLUG;
const AUTH_USERNAME = __ENV.AUTH_USERNAME;
const AUTH_PASSWORD = __ENV.AUTH_PASSWORD;

if (!BASE_URL || !SESSION_SLUG || !AUTH_USERNAME || !AUTH_PASSWORD) {
  throw new Error(
    "Required environment variables: BASE_URL, SESSION_SLUG, AUTH_USERNAME, AUTH_PASSWORD",
  );
}

export const options = {
  stages: [
    { duration: "4m", target: 100 }, // Gradually increase from 0 to 100 VUs over 120 seconds
    { duration: "2m", target: 100 }, // Maintain 100 VUs for 1 minute
    { duration: "4m", target: 0 }, // Gradually decrease from 100 to 0 VUs over 120 seconds
  ],
};

function buildUrl(path) {
  return `${BASE_URL}${path}`;
}

function getHeaders() {
  const credentials = `${AUTH_USERNAME}:${AUTH_PASSWORD}`;
  const encodedCredentials = encoding.b64encode(credentials);
  return {
    headers: {
      Authorization: `Basic ${encodedCredentials}`,
    },
  };
}

function startNow(headers) {
  let res = http.get(buildUrl(`/consents/${SESSION_SLUG}/hpv/start`), headers);
  check(res, { "status is 200": (r) => r.status === 200 });

  let csrfToken = res
    .html()
    .find("input[name=authenticity_token]")
    .first()
    .attr("value");
  let sessionSlug = res
    .html()
    .find("input[name=session_slug]")
    .first()
    .attr("value");
  let programmeType = res
    .html()
    .find("input[name=programme_type]")
    .first()
    .attr("value");

  let payload = {
    authenticity_token: csrfToken,
    session_slug: sessionSlug,
    programme_type: programmeType,
  };

  res = http.post(buildUrl("/consents"), payload, headers);
  check(res, {
    "on child name page": (r) =>
      r.status === 200 && r.body.includes("What is your child’s name?"),
  });

  return { html: res.html(), referer: res.request.url };
}

function getCsrfToken(html) {
  return html.find("input[name=authenticity_token]").first().attr("value");
}

function getFormAction(html) {
  return html.find("form").first().attr("action");
}

function submitForm(headers, formData, payload) {
  const formAction = getFormAction(formData.html);
  const submitUrl = buildUrl(formAction);

  const updatedPayload = {
    _method: "put",
    authenticity_token: getCsrfToken(formData.html),
    ...payload,
  };

  const updatedHeaders = {
    headers: {
      ...headers.headers,
      Referer: formData.referer,
    },
  };

  const res = http.post(submitUrl, updatedPayload, updatedHeaders);
  check(res, {
    "form submitted": (r) => r.status === 200,
  });
  return { response: res, html: res.html(), referer: res.request.url }; // Return html instead of body
}

function submitChildName(headers, formData) {
  const payload = {
    "consent_form[given_name]": "John",
    "consent_form[family_name]": "Smith",
    "consent_form[use_preferred_name]": "false",
  };

  const res = submitForm(headers, formData, payload);

  check(res.response, {
    "child name submitted": (r) =>
      r.body.includes("What is your child’s date of birth?"),
  });

  return res;
}

function submitDateOfBirth(headers, formData) {
  const today = new Date();
  const payload = {
    "consent_form[date_of_birth(3i)]": today.getDate().toString(),
    "consent_form[date_of_birth(2i)]": (today.getMonth() + 1).toString(),
    "consent_form[date_of_birth(1i)]": (today.getFullYear() - 13).toString(),
  };

  const res = submitForm(headers, formData, payload);

  check(res.response, {
    "date of birth submitted": (r) =>
      r.body.includes("Confirm your child’s school"),
  });

  return res;
}

function confirmSchool(headers, formData) {
  const payload = {
    "consent_form[school_confirmed]": "true",
  };

  const res = submitForm(headers, formData, payload);

  check(res.response, {
    "school confirmed": (r) => r.status === 200 && r.body.includes("About you"),
  });

  return res;
}

function submitAboutYou(headers, formData) {
  const payload = {
    "consent_form[parent_full_name]": "Sarah Smith",
    "consent_form[parent_relationship_type]": "mother",
    "consent_form[parent_email]": "sarah@example.com",
  };

  const res = submitForm(headers, formData, payload);

  check(res.response, {
    "about you submitted": (r) =>
      r.body.includes("Do you agree to them having the HPV vaccination?"),
  });

  return res;
}

function submitConsent(headers, formData) {
  const payload = {
    "consent_form[response]": "given",
  };

  const res = submitForm(headers, formData, payload);

  check(res.response, {
    "consent submitted": (r) =>
      r.body.includes("Is your child registered with a GP?"),
  });

  return res;
}

function submitGp(headers, formData) {
  const payload = {
    "consent_form[gp_response]": "yes",
    "consent_form[gp_name]": "Local GP",
  };

  const res = submitForm(headers, formData, payload);

  check(res.response, {
    "gp submitted": (r) => r.body.includes("Home address"),
  });

  return res;
}

function submitHomeAddress(headers, formData) {
  const payload = {
    "consent_form[address_line_1]": "123 High St",
    "consent_form[address_town]": "London",
    "consent_form[address_postcode]": "SW111AA",
  };

  const res = submitForm(headers, formData, payload);

  check(res.response, {
    "address submitted": (r) =>
      r.body.includes("Does your child have any severe allergies?"),
  });

  return res;
}

function submitHealthQuestion(
  headers,
  formData,
  questionNumber,
  nextPageIdentifier,
) {
  const payload = {
    "health_answer[response]": "no",
    question_number: questionNumber,
  };

  const res = submitForm(headers, formData, payload);

  check(res.response, {
    [`health question ${questionNumber} submitted`]: (r) =>
      r.body.includes(nextPageIdentifier),
  });

  return res;
}

function submitAnswersToHealthQuestions(headers, formData) {
  const questions = [
    { num: "0", nextPage: "medical conditions" },
    { num: "1", nextPage: "severe reaction" },
    { num: "2", nextPage: "extra support" },
    { num: "3", nextPage: "Check your answers" },
  ];

  let currentFormData = formData;
  for (const q of questions) {
    currentFormData = submitHealthQuestion(
      headers,
      currentFormData,
      q.num,
      q.nextPage,
    );
  }

  return currentFormData;
}

function submitConsentForm(headers, formData) {
  const payload = {
    _method: "put",
    authenticity_token: getCsrfToken(formData.html),
  };

  const res = http.post(buildUrl(getFormAction(formData.html)), payload, {
    headers: { ...headers.headers, Referer: formData.referer },
  });

  check(res, {
    "consent form submitted": (r) =>
      r.status === 200 &&
      r.body.includes("John Smith will get their HPV vaccination at school") &&
      r.body.includes("We’ve sent a confirmation to sarah@example.com"),
  });

  return { html: res.html(), referer: res.request.url };
}

export default function () {
  const headers = getHeaders();
  const formData = startNow(headers);
  // Initial pause before starting form
  sleep(randomIntBetween(3, 5));

  const dobFormData = submitChildName(headers, formData);
  sleep(randomIntBetween(15, 25));

  const schoolFormData = submitDateOfBirth(headers, dobFormData);
  sleep(randomIntBetween(5, 20));

  const confirmSchoolFormData = confirmSchool(headers, schoolFormData);
  sleep(randomIntBetween(3, 20));

  const aboutYouFormData = submitAboutYou(headers, confirmSchoolFormData);
  sleep(randomIntBetween(20, 45));

  const consentFormData = submitConsent(headers, aboutYouFormData);
  sleep(randomIntBetween(3, 20));

  const gpFormData = submitGp(headers, consentFormData);
  sleep(randomIntBetween(10, 35));

  const addressFormData = submitHomeAddress(headers, gpFormData);
  sleep(randomIntBetween(15, 35));

  const healthQuestionsFormData = submitAnswersToHealthQuestions(
    headers,
    addressFormData,
  );
  sleep(randomIntBetween(20, 35));

  // Final submission
  submitConsentForm(headers, healthQuestionsFormData);
}
