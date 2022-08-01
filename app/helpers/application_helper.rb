# frozen_string_literal: true

# ApplicationHelper
module ApplicationHelper
  def page_title(separator = " – ")
    [content_for(:title), "GOV.UK"].compact.join(separator)
  end

  def set_page_title(title)
    content_for(:title) { title }
  end

  def title_with_error_prefix(title, error)
    "#{t('page_titles.error_prefix') if error}#{title}"
  end

  def question_text_with_optional_suffix(page)
    page.question.is_optional? ? t("page.optional", question_text: page.question_text) : page.question_text
  end

  def format_paragraphs(text)
    simple_format(html_escape(text), class: "govuk-body", sanitize: true)
  end

  def main_classes(form)
    form.nil? || form.live? ? "" : "main--draft"
  end
end
