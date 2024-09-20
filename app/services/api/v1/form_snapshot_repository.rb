class Api::V1::FormSnapshotRepository
  class << self
    def find_with_mode(id:, mode:)
      Form.find_with_mode(id:, mode:)
    end
  end
end
