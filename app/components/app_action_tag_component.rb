class AppActionTagComponent < ViewComponent::Base
  attr_reader :status, :colour

  def initialize(status:, colour:)
    super

    @status = status
    @colour = colour
  end
end
