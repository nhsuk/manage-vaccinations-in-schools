# frozen_string_literal: true

class BulkRemoveParentsForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :current_user
  attr_reader :import, :consents

  attribute :remove_option, :string

  validates :remove_option,
            inclusion: {
              in: %w[unconsented_only all]
            },
            if: :consents_present?

  def initialize(import:, consents:, current_user:, **attributes)
    @import = import
    @consents = consents
    @current_user = current_user
    super(attributes)
  end

  def save!
    return false unless valid?

    if remove_option == "unconsented_only"
      import.destroy_parent_relationships_without_consent!(consents)
    else
      import.destroy_parent_relationships_and_invalidate_consents!(
        current_user,
        consents
      )
    end

    true
  end

  private

  def consents_present?
    @consents.any?
  end
end
