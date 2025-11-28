# frozen_string_literal: true

class BulkRemoveParentsForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :remove_option, :string

  def initialize(consents:, **attributes)
    @consents = consents
    super(attributes)
  end

  validates :remove_option,
            inclusion: {
              in: %w[unconsented all]
            },
            if: :consents_present?

  private

  def consents_present?
    @consents.any?
  end
end
