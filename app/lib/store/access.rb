module Store
  module Access
    def page_key(step)
      step.page_id.to_s
    end

    def database_id_key(step)
      step.database_id&.to_s
    end
  end
end
