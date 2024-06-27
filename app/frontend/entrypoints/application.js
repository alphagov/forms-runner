import { initAll } from 'govuk-frontend'
import {
  loadConsentStatus,
  CONSENT_STATUS
} from '../javascript/utils/cookie-consent'

import {
  installAnalyticsScript,
  setDefaultConsent
} from '../javascript/utils/google-analytics'
import { CookieBanner } from '../../components/cookie_banner_component/cookie-banner'

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
}

initAll()
