/**
 * @vitest-environment jsdom
 */

import {
  installAnalyticsScript,
  deleteGoogleAnalyticsCookies,
  sendPageViewEvent,
  attachExternalLinkTracker
} from '.'
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

  describe('sendPageViewEvent()', () => {
    describe('when the dataLayer array is not already present on the window object', () => {
      beforeEach(() => {
        window.dataLayer = undefined
      })

      it('creates the dataLayer array and pushes a pageView event', function () {
        sendPageViewEvent()
        expect(window.dataLayer).toContainEqual({
          event: 'page_view',
          page_view: {
            location: window.location,
            referrer: '',
            schema_name: 'simple_schema',
            status_code: 200,
            title: ''
          }
        })
      })
    })
    describe('when the dataLayer array is already present on the window object', () => {
      const existingDataLayerObject = {
        data: 'Some existing data in the dataLayer'
      }

      beforeEach(() => {
        window.dataLayer = [existingDataLayerObject]
      })

      it('the existing dataLayer content is preserved', function () {
        sendPageViewEvent()
        expect(window.dataLayer).toContainEqual(existingDataLayerObject)
      })

      it('the pageView event is pushed to the dataLayer', function () {
        sendPageViewEvent()
        expect(window.dataLayer).toContainEqual({
          event: 'page_view',
          page_view: {
            location: window.location,
            referrer: '',
            schema_name: 'simple_schema',
            status_code: 200,
            title: ''
          }
        })
      })
    })
  })

  describe('attachExternalLinkTracker()', () => {
    const targetLinkText = 'A link to example.com'
    const targetLinkUrl = 'http://example.com/'

    const existingDataLayerObject = {
      data: 'Some existing data in the dataLayer'
    }

    beforeEach(() => {
      window.document.body.innerHTML = `<a href="${targetLinkUrl}">${targetLinkText}</a>`
      window.dataLayer = [existingDataLayerObject]
    })

    it('the existing dataLayer content is preserved', function () {
      attachExternalLinkTracker()
      document.querySelector('a').click()
      expect(window.dataLayer).toContainEqual(existingDataLayerObject)
    })

    it('the navigation event is pushed to the dataLayer', function () {
      attachExternalLinkTracker()
      document.querySelector('a').click()
      expect(window.dataLayer).toContainEqual({
        event: 'event_data',
        event_data: {
          event_name: 'navigation',
          external: true,
          method: 'primary click',
          text: targetLinkText,
          type: 'generic link',
          url: targetLinkUrl
        }
      })
    })
  })
})
