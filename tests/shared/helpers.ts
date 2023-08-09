import { Page } from "@playwright/test";

export const answerWhoIsGivingConsent = async (p: Page) => {
  await p.fill('[name="consent_response[parent_name]"]', "Jane Doe");
  await p.fill('[name="consent_response[parent_phone]"]', "07412345678");
  await p.click("text=Mum");
};

export const answerHealthQuestions = async (p: Page) => {
  const radio = (n: number) =>
    `input[name="consent_response[question_${n}][response]"][value="no"]`;

  await p.click(radio(0));
  await p.click(radio(1));
  await p.click(radio(2));
  await p.click(radio(3));
};
