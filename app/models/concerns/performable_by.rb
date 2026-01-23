# frozen_string_literal: true

module PerformableBy
  extend ActiveSupport::Concern

  included do
    validates :performed_by_family_name,
              :performed_by_given_name,
              absence: {
                if: :performed_by_user
              }
  end

  PerformedBy =
    Struct.new(:given_name, :family_name) do
      def full_name
        FullNameFormatter.call(self, context: :internal)
      end
    end

  def performed_by
    return performed_by_user if performed_by_user

    if performed_by_given_name.present? || performed_by_family_name.present?
      PerformedBy.new(
        given_name: performed_by_given_name,
        family_name: performed_by_family_name
      )
    end
  end

  def performed_by=(user)
    self.performed_by_user = user
  end
end
