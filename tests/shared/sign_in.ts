export async function signInTestUser(page) {
  await page.getByLabel("Email address").fill("nurse@test");
  await page.getByLabel("Password").fill("nurse@test");
  await page.getByRole("button", { name: "Sign in" }).click();
}
