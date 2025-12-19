/**
 * @vitest-environment jsdom
 */

import { initFileValidation } from './index.js'
import { describe, beforeEach, afterEach, it, expect, vi } from 'vitest'

describe('File Validation', () => {
  let container

  beforeEach(() => {
    // Create a container for our test DOM
    container = document.createElement('div')
    document.body.appendChild(container)
  })

  afterEach(() => {
    // Clean up
    document.body.removeChild(container)
  })

  describe('initFileValidation', () => {
    it('adds validation to file inputs with data-max-file-size attribute', () => {
      // Setup DOM with GOV.UK form structure
      container.innerHTML = `
        <form>
          <div class="govuk-form-group">
            <label class="govuk-label" for="file-input">
              Upload a file
            </label>
            <input
              type="file"
              id="file-input"
              name="file"
              class="govuk-file-upload"
              data-max-file-size="7340032"
            />
          </div>
        </form>
      `

      initFileValidation()

      const input = container.querySelector('#file-input')
      const changeEvent = new Event('change', { bubbles: true })

      // Create a mock file that's too large (8MB)
      const largeFile = new File(['x'.repeat(8 * 1024 * 1024)], 'large.pdf', {
        type: 'application/pdf'
      })

      // Mock the files property
      Object.defineProperty(input, 'files', {
        value: [largeFile],
        writable: true
      })

      input.dispatchEvent(changeEvent)

      // Should show error
      expect(container.querySelector('.govuk-error-message')).toBeTruthy()
      expect(container.querySelector('.govuk-form-group--error')).toBeTruthy()
      expect(input.classList.contains('govuk-file-upload--error')).toBe(true)
      expect(input.value).toBe('') // File input should be cleared
    })

    it('does not show error for files within size limit', () => {
      container.innerHTML = `
        <form>
          <div class="govuk-form-group">
            <label class="govuk-label" for="file-input">
              Upload a file
            </label>
            <input
              type="file"
              id="file-input"
              name="file"
              class="govuk-file-upload"
              data-max-file-size="7340032"
            />
          </div>
        </form>
      `

      initFileValidation()

      const input = container.querySelector('#file-input')
      const changeEvent = new Event('change', { bubbles: true })

      // Create a mock file that's within limit (1MB)
      const smallFile = new File(['x'.repeat(1 * 1024 * 1024)], 'small.pdf', {
        type: 'application/pdf'
      })

      Object.defineProperty(input, 'files', {
        value: [smallFile],
        writable: true
      })

      input.dispatchEvent(changeEvent)

      // Should not show error
      expect(container.querySelector('.govuk-error-message')).toBeFalsy()
      expect(container.querySelector('.govuk-form-group--error')).toBeFalsy()
      expect(input.classList.contains('govuk-file-upload--error')).toBe(false)
    })

    it('clears previous errors when a valid file is selected', () => {
      container.innerHTML = `
        <form>
          <div class="govuk-form-group govuk-form-group--error">
            <label class="govuk-label" for="file-input">
              Upload a file
            </label>
            <span class="govuk-error-message" id="file-input-error">
              <span class="govuk-visually-hidden">Error: </span>
              Previous error
            </span>
            <input
              type="file"
              id="file-input"
              name="file"
              class="govuk-file-upload govuk-file-upload--error"
              data-max-file-size="7340032"
              aria-describedby="file-input-error"
            />
          </div>
        </form>
      `

      initFileValidation()

      const input = container.querySelector('#file-input')
      const changeEvent = new Event('change', { bubbles: true })

      // Create a valid file
      const validFile = new File(['content'], 'valid.pdf', {
        type: 'application/pdf'
      })

      Object.defineProperty(input, 'files', {
        value: [validFile],
        writable: true
      })

      input.dispatchEvent(changeEvent)

      // Error should be cleared
      expect(container.querySelector('.govuk-error-message')).toBeFalsy()
      expect(container.querySelector('.govuk-form-group--error')).toBeFalsy()
      expect(input.classList.contains('govuk-file-upload--error')).toBe(false)
    })

    it('prevents form submission when file is too large', () => {
      container.innerHTML = `
        <form>
          <div class="govuk-form-group">
            <label class="govuk-label" for="file-input">
              Upload a file
            </label>
            <input
              type="file"
              id="file-input"
              name="file"
              class="govuk-file-upload"
              data-max-file-size="7340032"
            />
          </div>
          <button type="submit">Submit</button>
        </form>
      `

      initFileValidation()

      const form = container.querySelector('form')
      const input = container.querySelector('#file-input')

      // Create a mock file that's too large
      const largeFile = new File(['x'.repeat(8 * 1024 * 1024)], 'large.pdf', {
        type: 'application/pdf'
      })

      Object.defineProperty(input, 'files', {
        value: [largeFile],
        writable: true
      })

      const submitEvent = new Event('submit', {
        bubbles: true,
        cancelable: true
      })
      const preventDefaultSpy = vi.spyOn(submitEvent, 'preventDefault')

      form.dispatchEvent(submitEvent)

      expect(preventDefaultSpy).toHaveBeenCalled()
    })

    it('allows form submission when file is within size limit', () => {
      container.innerHTML = `
        <form>
          <div class="govuk-form-group">
            <label class="govuk-label" for="file-input">
              Upload a file
            </label>
            <input
              type="file"
              id="file-input"
              name="file"
              class="govuk-file-upload"
              data-max-file-size="7340032"
            />
          </div>
          <button type="submit">Submit</button>
        </form>
      `

      initFileValidation()

      const form = container.querySelector('form')
      const input = container.querySelector('#file-input')

      // Create a valid file
      const validFile = new File(['content'], 'valid.pdf', {
        type: 'application/pdf'
      })

      Object.defineProperty(input, 'files', {
        value: [validFile],
        writable: true
      })

      const submitEvent = new Event('submit', {
        bubbles: true,
        cancelable: true
      })
      const preventDefaultSpy = vi.spyOn(submitEvent, 'preventDefault')

      form.dispatchEvent(submitEvent)

      expect(preventDefaultSpy).not.toHaveBeenCalled()
    })

    it('displays error message with correct file size information', () => {
      container.innerHTML = `
        <form>
          <div class="govuk-form-group">
            <label class="govuk-label" for="file-input">
              Upload a file
            </label>
            <input
              type="file"
              id="file-input"
              name="file"
              class="govuk-file-upload"
              data-max-file-size="7340032"
            />
          </div>
        </form>
      `

      initFileValidation()

      const input = container.querySelector('#file-input')
      const changeEvent = new Event('change', { bubbles: true })

      // Create a file that's 10MB
      const largeFile = new File(
        ['x'.repeat(10 * 1024 * 1024)],
        'large.pdf',
        { type: 'application/pdf' }
      )

      Object.defineProperty(input, 'files', {
        value: [largeFile],
        writable: true
      })

      input.dispatchEvent(changeEvent)

      const errorMessage = container.querySelector('.govuk-error-message')
      expect(errorMessage).toBeTruthy()
      expect(errorMessage.textContent).toContain('10.0 MB')
    })

    it('handles file inputs without data-max-file-size attribute', () => {
      container.innerHTML = `
        <form>
          <div class="govuk-form-group">
            <label class="govuk-label" for="file-input">
              Upload a file
            </label>
            <input
              type="file"
              id="file-input"
              name="file"
              class="govuk-file-upload"
            />
          </div>
        </form>
      `

      // Should not throw an error
      expect(() => initFileValidation()).not.toThrow()

      const input = container.querySelector('#file-input')
      const changeEvent = new Event('change', { bubbles: true })

      // Create a large file
      const largeFile = new File(['x'.repeat(100 * 1024 * 1024)], 'huge.pdf', {
        type: 'application/pdf'
      })

      Object.defineProperty(input, 'files', {
        value: [largeFile],
        writable: true
      })

      // Should not show error (no validation without data attribute)
      input.dispatchEvent(changeEvent)
      expect(container.querySelector('.govuk-error-message')).toBeFalsy()
    })

    it('sets aria-describedby correctly when showing errors', () => {
      container.innerHTML = `
        <form>
          <div class="govuk-form-group">
            <label class="govuk-label" for="file-input">
              Upload a file
            </label>
            <input
              type="file"
              id="file-input"
              name="file"
              class="govuk-file-upload"
              data-max-file-size="7340032"
            />
          </div>
        </form>
      `

      initFileValidation()

      const input = container.querySelector('#file-input')
      const changeEvent = new Event('change', { bubbles: true })

      const largeFile = new File(['x'.repeat(8 * 1024 * 1024)], 'large.pdf', {
        type: 'application/pdf'
      })

      Object.defineProperty(input, 'files', {
        value: [largeFile],
        writable: true
      })

      input.dispatchEvent(changeEvent)

      expect(input.getAttribute('aria-describedby')).toBe('file-input-error')
    })

    it('preserves existing aria-describedby when adding error', () => {
      container.innerHTML = `
        <form>
          <div class="govuk-form-group">
            <label class="govuk-label" for="file-input">
              Upload a file
            </label>
            <span class="govuk-hint" id="file-hint">
              File must be a PDF
            </span>
            <input
              type="file"
              id="file-input"
              name="file"
              class="govuk-file-upload"
              data-max-file-size="7340032"
              aria-describedby="file-hint"
            />
          </div>
        </form>
      `

      initFileValidation()

      const input = container.querySelector('#file-input')
      const changeEvent = new Event('change', { bubbles: true })

      const largeFile = new File(['x'.repeat(8 * 1024 * 1024)], 'large.pdf', {
        type: 'application/pdf'
      })

      Object.defineProperty(input, 'files', {
        value: [largeFile],
        writable: true
      })

      input.dispatchEvent(changeEvent)

      expect(input.getAttribute('aria-describedby')).toBe(
        'file-hint file-input-error'
      )
    })
  })
})
