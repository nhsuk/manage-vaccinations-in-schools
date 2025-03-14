# frozen_string_literal: true

class AppPatientVaccinationTableComponent < ViewComponent::Base
  def initialize(vaccination_records:, show_caption:, show_programme:)
    super

    @vaccination_records = vaccination_records.sort_by(&:performed_at).reverse

    @show_caption = show_caption
    @show_programme = show_programme
  end

  private

  attr_reader :vaccination_records, :show_caption, :show_programme
end
