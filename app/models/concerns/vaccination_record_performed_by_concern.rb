# frozen_string_literal: true

module VaccinationRecordPerformedByConcern
  extend ActiveSupport::Concern

  included do
    validates :performed_by_family_name,
              :performed_by_given_name,
              absence: {
                if: :performed_by_user
              }
  end

  def performed_by
    return performed_by_user if performed_by_user

    if performed_by_given_name.present? || performed_by_family_name.present?
      OpenStruct.new(
        given_name: performed_by_given_name,
        family_name: performed_by_family_name,
        full_name: -> do
          FullNameFormatter.call(
            self,
            context: :internal,
            parts_prefix: :performed_by
          )
        end
      )
    end
  end

  def performed_by=(user)
    self.performed_by_user = user
  end
end
