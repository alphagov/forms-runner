import { initAll } from 'govuk-frontend'
import dfeAutocomplete from 'dfe-autocomplete'
import {
  loadConsentStatus,
  CONSENT_STATUS
} from '../javascript/utils/cookie-consent'

import {
  installAnalyticsScript,
  setDefaultConsent,
  sendPageViewEvent,
  attachExternalLinkTracker,
  attachDetailsOpenTracker
} from '../javascript/utils/google-analytics'
import { CookieBanner } from '../../components/cookie_banner_component/cookie-banner'
import { CookiePage } from '../../components/cookie_consent_form_component/cookie-consent-form'

const analyticsConsentStatus = loadConsentStatus()

setDefaultConsent(analyticsConsentStatus === CONSENT_STATUS.GRANTED)

if (document.body.dataset.googleAnalyticsEnabled === 'true') {
  if (analyticsConsentStatus === CONSENT_STATUS.GRANTED) {
    installAnalyticsScript(window)
  }

  // Initialise cookie banner
  const banners = document.querySelectorAll('[data-module="cookie-banner"]')
  banners.forEach(function (banner) {
    new CookieBanner(banner).init({
      showBanner: analyticsConsentStatus === CONSENT_STATUS.UNKNOWN
    })
  })

  // Initialise cookie page
  const $cookiesPage = document.querySelector(
    '[data-module="app-cookies-page"]'
  )
  if ($cookiesPage) {
    new CookiePage($cookiesPage).init({
      allowAnalyticsCookies: analyticsConsentStatus === CONSENT_STATUS.GRANTED
    })
  }

  // push events regardless of consent value - if consent has not been granted
  // yet, GTM won't be loaded and no data is sent to Google analytics. Doing
  // this  now means that if consent is granted later on this page, the event
  // will be sent
  sendPageViewEvent()
  attachExternalLinkTracker()
  attachDetailsOpenTracker()
}

initAll()

window.dfeAutocomplete = dfeAutocomplete
