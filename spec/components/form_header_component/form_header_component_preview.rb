class FormHeaderComponent::FormHeaderComponentPreview < ViewComponent::Preview
  def default
    mode = Mode.new
    current_context = OpenStruct.new(form: 1, form_name: 'test', form_slug: 'test')
    render(FormHeaderComponent::View.new(current_context:, mode:, service_url_overide: '/form/1/test'))
  end

  def preview_draft
    mode = Mode.new('preview-draft')
    current_context = OpenStruct.new(form: 1, form_name: 'test', form_slug: 'test')
    render(FormHeaderComponent::View.new(current_context:, mode:, service_url_overide: '/form/1/test'))
  end

  def preview_live
    mode = Mode.new('preview-live')
    current_context = OpenStruct.new(form: 1, form_name: 'test', form_slug: 'test')
    render(FormHeaderComponent::View.new(current_context:, mode:, service_url_overide: '/form/1/test'))
  end
end
