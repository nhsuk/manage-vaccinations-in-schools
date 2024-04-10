export async function signInTestUser(
  page,
  username = "nurse.joy@example.com",
  password = "nurse.joy@example.com",
) {
  await page.goto("/users/sign-in");
  await page.getByLabel("Email address").fill(username);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Sign in" }).click();
}
