class Mode
  def initialize(mode_string = "form")
    @mode_string = mode_string
  end

  def live?
    @mode_string == "form" || !preview?
  end

  def preview?
    preview_draft? || preview_archived? || preview_live?
  end

  def preview_draft?
    @mode_string == "preview-draft"
  end

  def preview_archived?
    @mode_string == "preview-archived"
  end

  def preview_live?
    @mode_string == "preview-live"
  end

  def to_s
    @mode_string
  end

  def to_param
    live? ? "form" : @mode_string
  end
end
