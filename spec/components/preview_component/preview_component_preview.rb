class PreviewComponent::PreviewComponentPreview < ViewComponent::Preview
  def live
    mode = OpenStruct.new(live: true, preview?: false, preview_draft?: false, preview_live?: false)
    render(PreviewComponent::View.new(mode: mode))
  end

  def preview_draft
    mode = OpenStruct.new(live: false, preview?: true, preview_draft?: true, preview_live?: false, to_s: "preview-draft")
    render(PreviewComponent::View.new(mode: mode))
  end

  def preview_live
    mode = OpenStruct.new(live: false, preview?: true, preview_draft?: false, preview_live?: true, to_s: "preview-live")
    render(PreviewComponent::View.new(mode: mode))
  end
end
