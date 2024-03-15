class Mode
  def initialize(mode_string = "live")
    @mode_string = mode_string
  end

  def live
    !preview?
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
end
