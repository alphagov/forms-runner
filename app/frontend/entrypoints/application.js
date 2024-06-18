import { initAll } from 'govuk-frontend'
import { installAnalyticsScript } from '../javascript/google-tag'

if (document.body.dataset.googleAnalyticsEnabled === 'true') {
  installAnalyticsScript(window)
}

initAll()
