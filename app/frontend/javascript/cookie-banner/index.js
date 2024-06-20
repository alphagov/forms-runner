import { saveConsentStatus } from '../utils/cookie-consent'

import {
  installAnalyticsScript,
  deleteGoogleAnalyticsCookies,
  updateCookieConsent
} from '../utils/google-analytics'

export function CookieBanner ($module) {
  this.$module = $module
  this.$acceptButton = $module.querySelector('[data-function="accept-cookies"]')
  this.$rejectButton = $module.querySelector('[data-function="reject-cookies"]')
}

CookieBanner.prototype.init = function (options) {
  options = options || {}
  options.showBanner = options.showBanner || false

  const thisCallback = this.onClick.bind(this)
  this.$acceptButton.addEventListener('click', function () {
    thisCallback(true)
  })
  this.$rejectButton.addEventListener('click', function () {
    thisCallback(false)
  })

  if (options.showBanner) {
    this.show()
  }
}

CookieBanner.prototype.show = function () {
  this.$module.removeAttribute('hidden')
}

CookieBanner.prototype.hide = function () {
  this.$module.setAttribute('hidden', 'true')
}

CookieBanner.prototype.onSubmit = consentedToAnalyticsCookies => {
  saveConsentStatus(consentedToAnalyticsCookies)

  updateCookieConsent(consentedToAnalyticsCookies)

  if (consentedToAnalyticsCookies === false) {
    deleteGoogleAnalyticsCookies()
  } else {
    installAnalyticsScript(window)
  }
}

CookieBanner.prototype.onClick = function (allowAnalyticsCookies) {
  this.onSubmit(allowAnalyticsCookies)
  this.hide()
}
