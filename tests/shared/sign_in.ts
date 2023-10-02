export async function signInTestUser(
  page,
  username = "nurse.joy@test",
  password = "nurse.joy@test",
) {
  await page.goto("/users/sign-in");
  await page.getByLabel("Email address").fill(username);
  await page.getByLabel("Password").fill(password);
  await page.getByRole("button", { name: "Sign in" }).click();
}
