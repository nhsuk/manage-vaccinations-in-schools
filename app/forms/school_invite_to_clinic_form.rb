# frozen_string_literal: true

class SchoolInviteToClinicForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :programme_types, array: true

  validates :programme_types, presence: true

  def programme_types=(value)
    super(value&.compact_blank || [])
  end
end
