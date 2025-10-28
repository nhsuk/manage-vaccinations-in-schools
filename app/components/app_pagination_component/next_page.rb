# frozen_string_literal: true

class AppPaginationComponent::NextPage < GovukComponent::PaginationComponent::NextPage
  private

  def call
    tag.a(href:, class: ["#{brand}-pagination__next"], rel: suffix) do
      safe_join([body, divider, label_content])
    end
  end

  def arrow
    arrow_path = <<~PATH.squish
      m14.7 6.3 5 5c.2.2.3.4.3.7 0 .3-.1.5-.3.7l-5 5a1 1 0 0 1-1.4-1.4l3.3-3.3H5a1 1 0 0 1 0-2h11.6l-3.3-3.3a1 1 0 1 1 1.4-1.4Z
    PATH

    tag.svg(
      class: "nhsuk-icon nhsuk-icon--arrow-right",
      xmlns: "http://www.w3.org/2000/svg",
      height: "16",
      width: "16",
      focusable: "false",
      viewBox: "0 0 24 24",
      aria: {
        hidden: "true"
      }
    ) { tag.path(d: arrow_path) }
  end

  def title_classes
    class_names("#{brand}-pagination__title")
  end
end
