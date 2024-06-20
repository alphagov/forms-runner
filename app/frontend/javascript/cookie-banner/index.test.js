/**
 * @vitest-environment jsdom
 */

import { describe, beforeEach, test, expect } from 'vitest'
import { CookieBanner } from './index.js'

describe('CookieBanner', () => {
  let cookieBanner
  const cookieBannerHTML = `
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
    document.body.innerHTML = cookieBannerHTML
    cookieBanner = new CookieBanner(document.querySelector('#cookie-banner'))
  })

  test('Initialzes ok when given valid html', () => {
    expect(cookieBanner).toBeDefined()
  })

  describe('When given no options', () => {
    test('is hidden', () => {
      cookieBanner.init()
      expect(
        document.querySelector('#cookie-banner').getAttribute('hidden')
      ).toBe('true')
    })
  })

  test('show', () => {
    cookieBanner.show()
    expect(
      document.querySelector('#cookie-banner').hasAttribute('hidden')
    ).toBe(false)
  })
})
