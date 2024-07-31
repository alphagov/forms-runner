module FormRepository
  def self.find_with_mode(id:, mode:)
    raise NotImplementedError, "This #{self.class} cannot respond to:"
  end
end
