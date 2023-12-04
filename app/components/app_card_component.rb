class AppCardComponent < ViewComponent::Base
  erb_template <<-ERB
    <div class="nhsuk-card">
      <div class="nhsuk-card__content">
        <h2 class="nhsuk-card__heading nhsuk-heading-m">
          <%= @heading %>
        </h2>

        <%= content %>
      </div>
    </div>
  ERB

  def initialize(heading:)
    super

    @heading = heading
  end

  def render?
    content.present?
  end
end
