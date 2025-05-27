export function installAnalyticsScript (global) {
  const GTAG_ID = 'GTM-MFJWJNW'
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

export function sendPageViewEvent () {
  // Ideally this should be placed above the GTM container snippet and early within the <head> tags
  window.dataLayer = window.dataLayer || []
  window.dataLayer.push({
    // Where a property value is not available, set it as undefined
    event: 'page_view',
    page_view: {
      location: document.location,
      referrer: document.referrer,
      schema_name: 'simple_schema',
      status_code: 200,
      title: document.title
    }
  })
}

export function attachExternalLinkTracker () {
  const externalLinks = document.querySelectorAll(
    'a[href^="http"], a[href^="https"]'
  )
  externalLinks.forEach(function (externalLink) {
    externalLink.addEventListener('click', function (event) {
      const target = event.target
      window.dataLayer.push({
        event: 'event_data',
        event_data: {
          event_name: 'navigation',
          external: true,
          method: 'primary click',
          text: target.textContent,
          type: 'generic link',
          url: target.href
        }
      })
    })
  })
}

export function attachDetailsOpenTracker () {
  const detailsComponents = document.querySelectorAll('details')
  window.dataLayer = window.dataLayer || []
  detailsComponents.forEach(function (detailsElement) {
    detailsElement.addEventListener('toggle', function (event) {
      const summary = detailsElement.querySelector('summary')
      if (detailsElement.open) {
        window.dataLayer.push({
          event: 'event_data',
          event_data: {
            event_name: 'details_opened',
            url: window.location,
            text: summary.textContent
          }
        })
      }
    })
  })
}
