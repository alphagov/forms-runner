import { initAll } from 'govuk-frontend'
import { installAnalyticsScript } from '../javascript/utils/google-analytics'

if (document.body.dataset.googleAnalyticsEnabled === 'true') {
  installAnalyticsScript(window)
}

initAll()
