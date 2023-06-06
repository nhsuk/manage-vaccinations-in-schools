class AppBreadcrumbComponent < ViewComponent::Base
  def initialize(items:, classes: nil, attributes: {})
    super

    @items = items
    @classes = classes
    @attributes = attributes
  end
end
