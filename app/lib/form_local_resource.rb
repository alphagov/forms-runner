class FormLocalResource < ActiveYaml::Base
  set_root_path Rails.root.join("data")
  set_filename "forms"

  def self.find(*args, &block)
    reload(true)
    super(*args, &block)
  end
end
