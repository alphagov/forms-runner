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
end
