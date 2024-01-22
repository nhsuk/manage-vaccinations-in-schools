module ContentHelper
  def render_content_page(page_title)
    markdown = File.read("app/views/content/#{page_title}.md")
    content_with_erb_tags_replaced =
      ApplicationController.renderer.render(inline: markdown)

    # rubocop:disable Rails/HelperInstanceVariable
    @nhsuk_markdown =
      GovukMarkdown
        .render(content_with_erb_tags_replaced)
        .gsub("govuk-", "nhsuk-")
        .html_safe
    @page_title = t("page_titles.#{page_title}")
    # rubocop:enable Rails/HelperInstanceVariable

    render "rendered_markdown_template"
  end
end
