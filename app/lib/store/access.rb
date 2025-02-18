module Store
  module Access
    def page_key(step)
      step.page_id.to_s
    end

    def form_key(step)
      step.form_id.to_s
    end
  end
end
