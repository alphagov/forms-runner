/**
 * @vitest-environment jsdom
 */

import { describe, beforeEach, test, expect } from 'vitest'
import { CookiePage } from './cookie-consent-form.js'

describe('CookiePage', () => {
  let cookiePage
  const cookiePageHTML = `
    <div id="cookie-banner" class="govuk-cookie-banner" hidden="true" data-nosnippet role="region" aria-label="Cookies on <%= config[:service_name] %>" data-module="cookie-banner">
      <div class="govuk-cookie-banner__message govuk-width-container">
        <div class="govuk-grid-row">
          <div class="govuk-grid-column-two-thirds">
            <h2 class="govuk-cookie-banner__heading govuk-heading-m">Cookies on <%= config[:service_name] %></h2>
            <div class="govuk-cookie-banner__content">
              <p class="govuk-body">We’d like to use analytics cookies so we can understand how you use this website and make improvements.</p>
            </div>
          </div>
        </div>
        <div class="govuk-button-group">
          <button type="button" class="govuk-button" data-module="govuk-button" data-function="accept-cookies">
            Accept analytics cookies
          </button>
          <button type="button" class="govuk-button" data-module="govuk-button" data-function="reject-cookies">
            Reject analytics cookies
          </button>
          <a href="/cookies" class="govuk-link">How we use cookies</a>
        </div>
      </div>
    </div>`

  beforeEach(() => {
    document.body.innerHTML = cookiePageHTML
    cookiePage = new CookiePage(
      document.querySelector('[data-module="app-cookies-page"]')
    )
  })

  test('Initializes ok when given valid html', () => {
    expect(cookiePage).toBeDefined()
  })
})
