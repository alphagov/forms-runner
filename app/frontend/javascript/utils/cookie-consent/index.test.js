/**
 * @vitest-environment jsdom
 */

import {
  loadConsentStatus,
  saveConsentStatus,
  COOKIE_NAME,
  CONSENT_STATUS
} from './index.js'
import { describe, beforeEach, afterEach, it, expect } from 'vitest'

describe('Cookie', () => {
  const cookieValue = `${COOKIE_NAME}=true`

  afterEach(() => {
    // delete all cookies between tests
    const cookies = document.cookie.split(';')

    cookies.forEach(function (cookie) {
      const name = cookie.split('=')[0]
      document.cookie = name + '=;expires=Thu, 01 Jan 1970 00:00:00 GMT'
    })
  })

  describe('loadConsentStatus', () => {
    it('returns "GRANTED" when cookie set to true', () => {
      window.document.cookie = `${COOKIE_NAME}=true`
      expect(loadConsentStatus(cookieValue)).toBe(CONSENT_STATUS.GRANTED)
    })

    it('returns "DENIED" when cookie set to anything but true', () => {
      window.document.cookie = `${COOKIE_NAME}=asdj`
      expect(loadConsentStatus(cookieValue)).toBe(CONSENT_STATUS.DENIED)
    })

    it('returns "UNKNOWN" when cookie set to true', () => {
      window.document.cookie = 'wrong_cookie_name=true'
      expect(loadConsentStatus(cookieValue)).toBe(CONSENT_STATUS.UNKNOWN)
    })
  })

  describe('saveConsentStatus', () => {
    beforeEach(() => {
      Object.defineProperty(window.document, 'cookie', {
        writable: true,
        value: ''
      })
    })

    it('writes the correct value to the cookie when given true', () => {
      const fixedTestDate = new Date(2023, 1, 1, 0, 0, 0, 0)
      saveConsentStatus(true, fixedTestDate)
      expect(window.document.cookie).toBe(
        'analytics_consent=true; expires=Thu, 01 Feb 2024 00:00:00 GMT; path=/'
      )
    })

    it('writes the correct value to the cookie when given false', () => {
      const fixedTestDate = new Date(2023, 1, 1, 0, 0, 0, 0)
      saveConsentStatus(false, fixedTestDate)
      expect(window.document.cookie).toBe(
        'analytics_consent=false; expires=Thu, 01 Feb 2024 00:00:00 GMT; path=/'
      )
    })
  })

  describe('saveConsentStatus and loadConsentStatus', () => {
    it('writes the and reads correct value given true', () => {
      saveConsentStatus(true)
      expect(loadConsentStatus(cookieValue)).toBe(CONSENT_STATUS.GRANTED)
    })

    it('writes the and reads correct value given true', () => {
      saveConsentStatus(false)
      expect(loadConsentStatus(cookieValue)).toBe(CONSENT_STATUS.DENIED)
    })
  })
})
