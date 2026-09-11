class Api::V3::DeliveryConfigurationResource < ActiveResource::Base
  self.element_name = "delivery_configuration"
  self.site = Api::V3::FormDocumentResource.site
  self.prefix = Api::V3::FormDocumentResource.prefix_source
  self.include_format_in_path = false

  belongs_to :form
end
