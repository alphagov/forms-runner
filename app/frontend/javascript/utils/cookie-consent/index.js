export const COOKIE_NAME = 'analytics_consent'

export const CONSENT_STATUS = {
  GRANTED: 'CONSENT_GRANTED',
  DENIED: 'CONSENT_DENIED',
  UNKNOWN: 'CONSENT_UNKNOWN'
}

export function loadConsentStatus () {
  const cookies = document.cookie ? document.cookie.split('; ') : []
  for (let i = 0; i < cookies.length; i++) {
    const cookie = cookies[i].split('=')
    if (cookie[0] === COOKIE_NAME) {
      if (cookie[1] === 'true') {
        return CONSENT_STATUS.GRANTED
      }

      return CONSENT_STATUS.DENIED
    }
  }

  return CONSENT_STATUS.UNKNOWN
}

export function saveConsentStatus (consent, date) {
  date = date || new Date()
  date.setTime(date.getTime() + 365 * 24 * 60 * 60 * 1000)
  document.cookie =
    COOKIE_NAME + '=' + consent + '; expires=' + date.toGMTString() + '; path=/'
}
