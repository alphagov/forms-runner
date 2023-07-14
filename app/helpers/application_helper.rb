# frozen_string_literal: true

# ApplicationHelper
module ApplicationHelper
  def page_title(separator = " – ")
    [content_for(:title), "GOV.UK"].compact.join(separator)
  end

  def set_page_title(title)
    content_for(:title) { title }
  end

  def form_title(page_name:, form_name:, mode:, error: false)
    mode_string = if mode.preview_draft?
                    " - #{t('mode.title_text_preview-draft')}"
                  elsif mode.preview_live?
                    " - #{t('mode.title_text_preview-live')}"
                  else
                    ""
                  end
    "#{t('page_titles.error_prefix') if error}#{page_name}#{mode_string} - #{form_name}"
  end

  def question_text_with_optional_suffix(page, mode)
    mode_string = hidden_text_mode(mode)
    question = page.question.show_optional_suffix ? t("page.optional", question_text: page.question_text) : page.question_text

    if mode_string.blank?
      question
    else
      [question, mode_string].join(" ")
    end
  end

  def hidden_text_mode(mode)
    return "" unless mode.preview?

    mode_name = if mode.preview_draft?
                  "draft"
                elsif mode.preview_live?
                  "live"
                end
    "<span class='govuk-visually-hidden'>&nbsp;#{t("page.#{mode_name}_preview".to_s)}</span>".html_safe
  end

  def format_paragraphs(text)
    simple_format(html_escape(text), class: "govuk-body", sanitize: true)
  end

  def govuk_assets_path
    "/node_modules/govuk-frontend/govuk/assets"
  end
end
