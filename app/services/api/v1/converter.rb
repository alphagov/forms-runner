class Api::V1::Converter
  def to_api_v1_form_snapshot(form_document)
    form_snapshot = form_document.deep_dup

    form_id = form_snapshot.delete("form_id")
    form_snapshot = { "id" => form_id, **form_snapshot }

    steps = form_snapshot.delete("steps") || {}
    form_snapshot["pages"] = steps.map { |step| to_api_v1_page(step) }

    form_snapshot
  end

  def to_api_v1_page(step)
    page = {
      "id" => step["id"],
      "position" => step["position"],
      "next_page" => step["next_step_id"],
    }
    if step["type"] == "question_page"
      page.merge!(step["data"])
    end
    page["routing_conditions"] = step.fetch("routing_conditions", [])
    page
  end
end
