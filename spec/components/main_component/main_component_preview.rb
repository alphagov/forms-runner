class MainComponent::MainComponentPreview < ViewComponent::Preview
  def default
    render(MainComponent::View.new(is_component_preview: true))
  end
end
