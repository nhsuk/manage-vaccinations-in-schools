describe("Offline functionality", () => {
  it("switches between going online and offline", () => {
    cy.visit("/");
    cy.getBySelector("campaigns").first().click();

    cy.getBySelector("online-status").should("contain", "Online");
    cy.getBySelector("offline-indicator").should("not.be.visible");

    cy.getBySelector("switch-online-offline").contains("Go offline").click();
    cy.getBySelector("online-status").should("contain", "Offline");
    cy.getBySelector("offline-indicator").should("be.visible");

    cy.getBySelector("switch-online-offline").contains("Go online").click();
    cy.getBySelector("online-status").should("contain", "Online");
    cy.getBySelector("offline-indicator").should("not.be.visible");
  });
});
