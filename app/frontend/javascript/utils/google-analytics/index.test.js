/**
 * @vitest-environment jsdom
 */

import { installAnalyticsScript, deleteGoogleAnalyticsCookies } from '.'
import { describe, beforeEach, afterEach, it, expect } from 'vitest'

describe('google_tag.mjs', () => {
  afterEach(() => {
    document.getElementsByTagName('html')[0].innerHTML = ''
  })

  describe('installAnalyticsScript()', () => {
    it('adds the google analytics script tag to the DOM', function () {
      installAnalyticsScript(window)
      expect(
        document.querySelectorAll(
          'script[src^="https://www.googletagmanager.com/gtm.js"]'
        ).length
      ).toBe(1)
    })

    describe('when google analytics is already present on the window', () => {
      beforeEach(() => {
        window.document.write = ''
        Object.defineProperty(window, 'ga', {
          writable: true,
          value: true
        })
      })

      it('does not add the google analytics script tag to the DOM', function () {
        installAnalyticsScript(window)
        expect(
          document.querySelectorAll(
            'script[src^="https://www.googletagmanager.com/gtm.js"]'
          ).length
        ).toBe(0)
      })
    })
  })

  describe('deleteGoogleAnalyticsCookies()', () => {
    it('removes google cookies', function () {
      document.cookie = '_ga=GA1.1.120966789.1687349767'
      document.cookie = 'analytics_consent=true'
      document.cookie = '_ga_B0CQCNQ8PH=GS1.1.1687430125.5.0.1687430125.0.0.0'

      deleteGoogleAnalyticsCookies()
      expect(document.cookie).toContain('analytics_consent=true')
    })
  })
})
