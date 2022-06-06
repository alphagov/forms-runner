class FormRepository
  def initialize(resource: FormApiResource)
    @resource = resource
  end

  def find(id)
    form_data = @resource.find(id).attributes
    Form.new(**form_data)
  end
end
