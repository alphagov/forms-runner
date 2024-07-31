class FormService
  def self.find(id)
    repository.find(id)
  end

  def self.find_with_mode(id:, mode:)
    raise ActiveResource::ResourceNotFound.new(404, "Not Found") unless id.to_s =~ /^[[:alnum:]]+$/

    find_from_repository(id:, mode:)
  end

  def self.find_from_repository(id:, mode:)
    repository.find_with_mode(id:, mode: mode_string(mode))
  end

  def self.repository
    Settings.features.direct_api_enabled ? FormDirect : FormResource
  end

  def self.mode_string(mode)
    return "draft" if mode.preview_draft?
    return "archived" if mode.preview_archived?

    "live" if mode.live? || mode.preview_live?
  end
end
