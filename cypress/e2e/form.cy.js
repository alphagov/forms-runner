describe('Form', function () {
  beforeEach(function () {
    cy.visit(`/${this.formId}`)
  })

  it('contains the beta phase banner', function () {
    cy.findAllByText('Beta')
      .first()
      .should('be.visible')
    cy.findAllByText('feedback')
      .first()
      .should('be.visible')
      .should('have.attr', 'href')
      .and('equal', 'mailto:govuk-forms@digital.cabinet-office.gov.uk')
  })
})
