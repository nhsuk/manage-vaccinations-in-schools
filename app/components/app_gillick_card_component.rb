class AppGillickCardComponent < ViewComponent::Base
  def initialize(assessment:)
    super

    @assessment = assessment
  end
end
