class AppPatientTableFilterComponent < ViewComponent::Base
  def initialize(tab_id:, filter_actions: false)
    super

    @tab_id = tab_id
    @filter_actions = filter_actions
  end
end
