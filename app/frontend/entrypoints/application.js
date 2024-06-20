import { initAll } from 'govuk-frontend'
import {
  loadConsentStatus,
  saveConsentStatus,
  CONSENT_STATUS
} from '../javascript/utils/cookie-consent'

import {
  installAnalyticsScript,
  deleteGoogleAnalyticsCookies,
  setDefaultConsent,
  updateCookieConsent
} from '../javascript/utils/google-analytics'
import { CookieBanner } from '../javascript/cookie-banner'

const analyticsConsentStatus = loadConsentStatus()

setDefaultConsent(analyticsConsentStatus === CONSENT_STATUS.GRANTED)

if (
  document.body.dataset.googleAnalyticsEnabled === 'true' &&
  analyticsConsentStatus === CONSENT_STATUS.GRANTED
) {
  installAnalyticsScript(window)
}

// Initialise cookie banner
const $banners = document.querySelectorAll('[data-module="cookie-banner"]')
$banners.forEach(function ($banner) {
  new CookieBanner($banner).init({
    showBanner: analyticsConsentStatus === CONSENT_STATUS.UNKNOWN,
    onSubmit: handleUpdateConsent
  })
})

function handleUpdateConsent (consentedToAnalyticsCookies) {
  saveConsentStatus(consentedToAnalyticsCookies)

  updateCookieConsent(consentedToAnalyticsCookies)

  if (consentedToAnalyticsCookies === false) {
    deleteGoogleAnalyticsCookies()
  } else {
    installAnalyticsScript(window)
  }
}
initAll()
