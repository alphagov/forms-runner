/**
 * Client-side file validation for file upload inputs
 * Validates file size before form submission to provide immediate feedback
 */

const BYTES_IN_MB = 1024 * 1024

/**
 * Format bytes to a human-readable size
 * @param {number} bytes - The number of bytes
 * @returns {string} Formatted file size
 */
function formatFileSize (bytes) {
  if (bytes === 0) return '0 Bytes'

  const mb = bytes / BYTES_IN_MB
  if (mb >= 1) {
    return `${mb.toFixed(1)} MB`
  }

  const kb = bytes / 1024
  return `${kb.toFixed(1)} KB`
}

/**
 * Show error message using GOV.UK Design System error pattern
 * @param {HTMLInputElement} input - The file input element
 * @param {string} errorMessage - The error message to display
 */
function showError (input, errorMessage) {
  const formGroup = input.closest('.govuk-form-group')
  if (!formGroup) return

  // Add error class to form group
  formGroup.classList.add('govuk-form-group--error')

  // Check if error message already exists
  let errorSpan = formGroup.querySelector('.govuk-error-message')

  if (!errorSpan) {
    // Create error message element
    errorSpan = document.createElement('span')
    errorSpan.className = 'govuk-error-message'
    errorSpan.id = `${input.id}-error`

    const visuallyHiddenSpan = document.createElement('span')
    visuallyHiddenSpan.className = 'govuk-visually-hidden'
    visuallyHiddenSpan.textContent = 'Error: '

    errorSpan.appendChild(visuallyHiddenSpan)

    // Insert error message before the file input (or after hint if present)
    const hint = formGroup.querySelector('.govuk-hint')
    const insertBefore = hint || input
    insertBefore.parentNode.insertBefore(errorSpan, insertBefore)
  }

  // Update error message text (preserving the visually-hidden span)
  const visuallyHidden = errorSpan.querySelector('.govuk-visually-hidden')
  errorSpan.textContent = errorMessage
  if (visuallyHidden) {
    errorSpan.insertBefore(visuallyHidden, errorSpan.firstChild)
  }

  // Add error class to input
  input.classList.add('govuk-file-upload--error')

  // Update aria-describedby
  const ariaDescribedBy = input.getAttribute('aria-describedby') || ''
  if (!ariaDescribedBy.includes(errorSpan.id)) {
    input.setAttribute(
      'aria-describedby',
      ariaDescribedBy ? `${ariaDescribedBy} ${errorSpan.id}` : errorSpan.id
    )
  }
}

/**
 * Clear error message from a file input
 * @param {HTMLInputElement} input - The file input element
 */
function clearError (input) {
  const formGroup = input.closest('.govuk-form-group')
  if (!formGroup) return

  // Remove error class from form group
  formGroup.classList.remove('govuk-form-group--error')

  // Remove error message
  const errorSpan = formGroup.querySelector('.govuk-error-message')
  if (errorSpan) {
    errorSpan.remove()
  }

  // Remove error class from input
  input.classList.remove('govuk-file-upload--error')

  // Clean up aria-describedby
  const ariaDescribedBy = input.getAttribute('aria-describedby')
  if (ariaDescribedBy) {
    const errorId = `${input.id}-error`
    const updatedAriaDescribedBy = ariaDescribedBy
      .split(' ')
      .filter(id => id !== errorId)
      .join(' ')

    if (updatedAriaDescribedBy) {
      input.setAttribute('aria-describedby', updatedAriaDescribedBy)
    } else {
      input.removeAttribute('aria-describedby')
    }
  }
}

/**
 * Validate file size for a file input
 * @param {HTMLInputElement} input - The file input element
 * @returns {boolean} Whether the file is valid
 */
function validateFileSize (input) {
  const file = input.files[0]

  // No file selected - clear any existing errors
  if (!file) {
    clearError(input)
    return true
  }

  const maxSizeInBytes = parseInt(input.dataset.maxFileSize, 10)

  // No max size specified - skip validation
  if (!maxSizeInBytes) {
    return true
  }

  // File is within size limits
  if (file.size <= maxSizeInBytes) {
    clearError(input)
    return true
  }

  // File is too large - show error
  const maxSizeMB = maxSizeInBytes / BYTES_IN_MB
  const actualSize = formatFileSize(file.size)
  const errorMessage = `The selected file must be smaller than ${maxSizeMB}MB (file is ${actualSize})`

  showError(input, errorMessage)

  // Clear the file input
  input.value = ''

  return false
}

/**
 * Initialize file validation for all file inputs with data-max-file-size attribute
 */
export function initFileValidation () {
  const fileInputs = document.querySelectorAll('input[type="file"][data-max-file-size]')

  fileInputs.forEach(input => {
    // Validate on file selection
    input.addEventListener('change', (event) => {
      validateFileSize(event.target)
    })
  })

  // Also validate on form submission as a final check
  document.addEventListener('submit', (event) => {
    const form = event.target
    const fileInputs = form.querySelectorAll('input[type="file"][data-max-file-size]')

    let hasErrors = false
    fileInputs.forEach(input => {
      if (!validateFileSize(input)) {
        hasErrors = true
      }
    })

    if (hasErrors) {
      event.preventDefault()
      // Focus on the first error
      const firstError = form.querySelector('.govuk-file-upload--error')
      if (firstError) {
        firstError.focus()
      }
    }
  })
}
