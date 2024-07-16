import { handleUpdateConsent } from '../../frontend/javascript/utils/cookie-consent'

export function CookiePage ($module) {
  this.$module = $module
}

CookiePage.prototype.init = function (options) {
  this.$cookiePage = this.$module

  if (!this.$cookiePage) {
    return
  }

  options = options || {}
  options.allowAnalyticsCookies = options.allowAnalyticsCookies || false

  this.$cookieForm = this.$cookiePage.querySelector('.js-cookies-page-form')
  this.$noJsMessage = this.$cookiePage.querySelector(
    '.js-cookies-page__no-js-message'
  )
  this.$cookieFormFieldsets = this.$cookieForm.querySelectorAll(
    '.js-cookies-page-form-fieldset'
  )
  this.$analyticsFieldset = this.$cookieForm.querySelector('#analytics')

  this.$successNotification = this.$cookiePage.querySelector(
    '.js-cookies-page-success'
  )

  this.showUserPreference(
    this.$analyticsFieldset,
    options.allowAnalyticsCookies
  )

  this.$cookieForm.removeAttribute('hidden')

  this.$noJsMessage.setAttribute('hidden', true)

  this.$cookieForm.addEventListener('submit', this.savePreferences.bind(this))
}

CookiePage.prototype.onSubmit = handleUpdateConsent

CookiePage.prototype.savePreferences = function (event) {
  event.preventDefault()

  const selectedItem = this.$analyticsFieldset.querySelector(
    'input[name=analytics]:checked'
  ).value

  this.onSubmit(selectedItem === 'yes')
  this.showSuccessNotification()
}

CookiePage.prototype.showUserPreference = function (
  $cookieFormFieldset,
  preference
) {
  const radioValue = preference ? 'yes' : 'no'
  const radio = $cookieFormFieldset.querySelector(
    'input[name=analytics][value=' + radioValue + ']'
  )
  radio.checked = true
}

CookiePage.prototype.showSuccessNotification = function () {
  this.$successNotification.removeAttribute('hidden')

  // Set tabindex to -1 to make the element focusable with JavaScript.
  // GOV.UK Frontend will remove the tabindex on blur as the component doesn't
  // need to be focusable after the user has read the text.
  if (!this.$successNotification.getAttribute('tabindex')) {
    this.$successNotification.setAttribute('tabindex', '-1')
  }

  this.$successNotification.focus()

  // scroll to the top of the page
  window.scrollTo(0, 0)
}

export default CookiePage
