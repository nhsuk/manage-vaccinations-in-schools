# frozen_string_literal: true

class AppProgrammeSelectionFormComponent < ViewComponent::Base
  def initialize(programmes, active:)
    super

    @programmes = programmes
    @active_programme = active
  end

  private

  attr_reader :programmes, :active_programme
end
