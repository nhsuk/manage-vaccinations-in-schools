# frozen_string_literal: true

class AppPaginationComponent < GovukComponent::PaginationComponent
  def before_render
    @page_items =
      if pagy.present?
        build_items
      elsif items.any?
        items
      else
        []
      end

    @previous_content = previous_page || build_previous&.render_in(view_context)
    @next_content = next_page || build_next&.render_in(view_context)
  end

  private

  def default_attributes
    {
      aria: {
        label: landmark_label
      },
      class: "nhsuk-pagination nhsuk-pagination--numbered"
    }
  end

  def build_previous
    return unless pagy&.prev

    AppPaginationComponent::PreviousPage.new(
      href: pagy_url_for(pagy, pagy.prev),
      text: @previous_text || default_adjacent_text(:prev),
      block_mode: block_mode?
    )
  end

  def build_next
    return unless pagy&.next

    AppPaginationComponent::NextPage.new(
      href: pagy_url_for(pagy, pagy.next),
      text: @next_text || default_adjacent_text(:next),
      block_mode: block_mode?
    )
  end
end
