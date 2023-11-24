class AppEmptyListComponent < ViewComponent::Base
  erb_template <<-ERB
    <div class="app-empty-list">
      <div class="nhsuk-card__content">
        <h2 class="nhsuk-heading-l">No results</h2>
        <p><%= @message %></p>
      </div>
    </div>
  ERB

  def initialize(message:)
    super

    @message = message
  end
end
