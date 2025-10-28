# frozen_string_literal: true

class AppPaginationComponent::PreviousPage < GovukComponent::PaginationComponent::PreviousPage
  private

  def call
    tag.a(href:, class: ["#{brand}-pagination__previous"], rel: suffix) do
      safe_join([body, divider, label_content])
    end
  end

  def arrow
    arrow_path = <<~PATH.squish
      M10.7 6.3c.4.4.4 1 0 1.4L7.4 11H19a1 1 0 0 1 0 2H7.4l3.3 3.3c.4.4.4 1 0 1.4a1 1 0 0 1-1.4 0l-5-5A1 1 0 0 1 4 12c0-.3.1-.5.3-.7l5-5a1 1 0 0 1 1.4 0Z
    PATH

    tag.svg(
      class: "nhsuk-icon nhsuk-icon--arrow-left",
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
