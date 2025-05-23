# frozen_string_literal: true

module GelatineVaccinesConcern
  extend ActiveSupport::Concern

  def vaccine_may_contain_gelatine?
    vaccines.any?(&:contains_gelatine?)
  end
end
