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
  options.onSubmit = options.onSubmit || function () {}

  this.$cookieForm = this.$cookiePage.querySelector('.js-cookies-page-form')
  this.$cookieFormFieldsets = this.$cookieForm.querySelectorAll(
    '.js-cookies-page-form-fieldset'
  )
  this.$analyticsFieldset = this.$cookieForm.querySelector('#analytics')

  this.$successNotification = this.$cookiePage.querySelector(
    '.js-cookies-page-success'
  )

  this.onSubmit(options.onSubmit)

  this.showUserPreference(
    this.$analyticsFieldset,
    options.allowAnalyticsCookies
  )
  this.$analyticsFieldset.removeAttribute('hidden')

  // Show submit button
  this.$cookieForm
    .querySelector('.js-cookies-form-button')
    .removeAttribute('hidden')
  this.$cookieForm.addEventListener('submit', this.savePreferences.bind(this))
}

CookiePage.prototype.onSubmit = function (cb) {
  this.onSubmitCallback = cb
}

CookiePage.prototype.savePreferences = function (event) {
  event.preventDefault()

  const selectedItem = this.$analyticsFieldset.querySelector(
    'input[name=analytics]:checked'
  ).value

  this.onSubmitCallback(selectedItem === 'yes')
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
