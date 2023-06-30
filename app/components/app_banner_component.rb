class AppBannerComponent < ViewComponent::Base
  attr_reader :title, :explanation, :colour

  def initialize(title:, explanation:, colour:)
    super

    @title = title
    @explanation = explanation
    @colour = colour
  end
end
