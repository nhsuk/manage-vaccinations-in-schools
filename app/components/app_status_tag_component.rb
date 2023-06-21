class AppStatusTagComponent < ViewComponent::Base
  BASE_CLASSES = %w[app-status-tag nhsuk-tag].freeze

  attr_reader :status, :colour, :icon

  def initialize(status:, colour:, icon: nil)
    super

    @status = status
    @colour = colour
    @icon = icon
    @classes = BASE_CLASSES
  end

  def css_class
    {
      white: ["nhsuk-tag--white"],
      green: ["nhsuk-tag--green"],
      red: ["nhsuk-tag--red"],
      orange: ["nhsuk-tag--orange"],
      blue: ["nhsuk-tag--blue"],
      grey: ["nhsuk-tag--grey"]
    }.fetch(@colour)
  end

  def svg_icon
    return @icon if @icon
  end

  def div_attributes
    { class: @classes + css_class }
  end
end
