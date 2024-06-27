import { initAll } from 'govuk-frontend'
import {
  loadConsentStatus,
  CONSENT_STATUS,
  saveConsentStatus
} from '../javascript/utils/cookie-consent'

import {
  installAnalyticsScript,
  setDefaultConsent,
  updateCookieConsent,
  deleteGoogleAnalyticsCookies
} from '../javascript/utils/google-analytics'
import { CookieBanner } from '../../components/cookie_banner_component/cookie-banner'
import { CookiePage } from '../javascript/cookie-page.js'

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
      allowAnalyticsCookies: analyticsConsentStatus === CONSENT_STATUS.GRANTED,
      onSubmit: handleUpdateConsent
    })
  }
}

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
