export function installAnalyticsScript (global) {
  const GTAG_ID = 'GTM-T2SJXKKQ'
  if (!window.ga) {
    ;(function (w, d, s, l, i) {
      w[l] = w[l] || []
      w[l].push({
        'gtm.start': new Date().getTime(),
        event: 'gtm.js'
      })

      const j = d.createElement(s)
      const dl = l !== 'dataLayer' ? '&l=' + l : ''

      j.async = true
      j.src = 'https://www.googletagmanager.com/gtm.js?id=' + i + dl
      document.head.appendChild(j)
    })(global, document, 'script', 'dataLayer', GTAG_ID)
  }
}

export function deleteGoogleAnalyticsCookies () {
  const cookies = document.cookie ? document.cookie.split('; ') : []
  cookies.forEach(function (cookie) {
    if (
      cookie.startsWith('_ga') ||
      cookie.startsWith('_gid') ||
      cookie.startsWith('_gat')
    ) {
      const domain = window.location.hostname
      const cookieToDelete =
        cookie.split('=')[0] +
        '=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=' +
        domain
      document.cookie = cookieToDelete
    }
  })
}

export function setDefaultConsent (consentedToAnalyticsCookies) {
  window.dataLayer = window.dataLayer || []
  window.dataLayer.push([
    'consent',
    'default',
    {
      ad_storage: 'denied',
      analytics_storage: consentedToAnalyticsCookies ? 'granted' : 'denied'
    }
  ])
}

export function updateCookieConsent (consentedToAnalyticsCookies) {
  window.dataLayer = window.dataLayer || []
  window.dataLayer.push([
    'consent',
    'update',
    {
      analytics_storage: consentedToAnalyticsCookies ? 'granted' : 'denied'
    }
  ])
}
