export function CookieBanner ($module) {
  this.$module = $module
  this.$acceptButton = $module.querySelector('[data-function="accept-cookies"]')
  this.$rejectButton = $module.querySelector('[data-function="reject-cookies"]')
}

CookieBanner.prototype.init = function (options) {
  options = options || {}
  options.showBanner = options.showBanner || false
  options.onSubmit = options.onSubmit || function () {}

  this.onSubmit(options.onSubmit)
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

CookieBanner.prototype.onSubmit = function (cb) {
  this.onSubmitCallback = cb
}

CookieBanner.prototype.onClick = function (allowAnalyticsCookies) {
  this.onSubmitCallback(allowAnalyticsCookies)
  this.hide()
}
