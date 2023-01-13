describe('Offline functionality', () => {
  it('switches between going online and offline', () => {
    cy.visit('/children');

    cy.getBySelector('online-status').should('contain', 'Online');

    cy.getBySelector('switch-online-offline')
      .contains('Go Offline')
      .click();
    cy.getBySelector('online-status').should('contain', 'Offline');

    cy.getBySelector('switch-online-offline')
      .contains('Go Online')
      .click();
    cy.getBySelector('online-status').should('contain', 'Online');
  })
})
