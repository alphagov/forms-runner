class MainComponent::MainComponentPreview < ViewComponent::Preview
  def deafult
    render(MainComponent::View.new(mode: nil, is_component_preview: true))
  end

  def draft_preview
    render(MainComponent::View.new(mode: "preview-draft", is_component_preview: true)) do
      Array.new(10) { content_tag(:p, "This is the draft preview example content.") }.join.html_safe
    end
  end

  def live_preview
    render(MainComponent::View.new(mode: "preview-live", is_component_preview: true)) do
      Array.new(10) { content_tag(:p, "This is the live preview example content.") }.join.html_safe
    end
  end

  def draft_preview_question
    render(MainComponent::View.new(mode: "preview-draft", is_question: true, is_component_preview: true)) do
      Array.new(10) { content_tag(:p, "This is the draft preview example content for question pages.") }.join.html_safe
    end
  end

  def live_preview_question
    render(MainComponent::View.new(mode: "preview-live", is_question: true, is_component_preview: true)) do
      Array.new(10) { content_tag(:p, "This is the live preview example content for question pages.") }.join.html_safe
    end
  end
end
