describe("Recording child vaccination", () => {
  it("Records a child ", () => {
    cy.visit("/");
    cy.getBySelector("campaigns").first().click();
    cy.getBySelector("children").should("have.length", 100);

    // TODO: Need to find a way to setup a test environment before this test
    //       will will be meaningful. i.e. we need a fresh copy of the example
    //       campaign, but that will also mean running in a test env, which also
    //       means running a separate Rails/Puma server ... so that's a bit of
    //       work.
    // cy.getBySelector("child-status").first().should("have.text", "Not yet");

    cy.getBySelector("child-link").first().click();
    cy.getBySelector("confirm-button").click();
    cy.getBySelector("record-another-vaccination-link").click();
    cy.getBySelector("child-status").first().should("have.text", "Vaccinated");
  });
});
