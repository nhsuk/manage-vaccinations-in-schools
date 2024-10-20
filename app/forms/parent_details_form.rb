# frozen_string_literal: true

class ParentDetailsForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :parent, :patient

  attribute :email, :string
  attribute :full_name, :string
  attribute :phone, :string
  attribute :phone_receive_updates, :boolean
  attribute :parental_responsibility, :boolean
  attribute :relationship_other_name, :string
  attribute :relationship_type, :string

  validates :email, notify_safe_email: true
  validates :phone,
            presence: {
              if: :phone_receive_updates
            },
            phone: {
              allow_blank: true
            }

  with_options if: :can_change_name_or_relationship? do
    validates :full_name, presence: true
    validates :relationship_type,
              inclusion: {
                in: ParentRelationship.types.keys
              }
  end

  with_options if: :requires_parental_responsibility? do
    validates :relationship_other_name, presence: true, length: { maximum: 300 }
    validates :parental_responsibility, inclusion: [true]
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      parent.email = email
      parent.full_name = full_name if can_change_name_or_relationship?
      parent.phone = phone
      parent.phone_receive_updates = phone_receive_updates || false
      parent.save!

      if can_change_name_or_relationship?
        parent
          .parent_relationships
          .find_or_initialize_by(patient:)
          .update!(type: relationship_type, other_name: relationship_other_name)
      end
    end

    true
  rescue ActiveRecord::RecordInvalid
    errors.add(:base, "Failed to save changes")
    false
  end

  def can_change_name_or_relationship?
    parent.draft?
  end

  def requires_parental_responsibility?
    can_change_name_or_relationship? && relationship_type == "other"
  end
end
