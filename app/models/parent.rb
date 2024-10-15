# frozen_string_literal: true

# == Schema Information
#
# Table name: parents
#
#  id                           :bigint           not null, primary key
#  contact_method_other_details :text
#  contact_method_type          :string
#  email                        :string
#  full_name                    :string
#  phone                        :string
#  phone_receive_updates        :boolean          default(FALSE), not null
#  recorded_at                  :datetime
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#
# Indexes
#
#  index_parents_on_email  (email)
#
class Parent < ApplicationRecord
  include Recordable

  audited

  before_save :reset_unused_fields

  has_many :parent_relationships
  has_many :patients, through: :parent_relationships

  has_and_belongs_to_many :class_imports
  has_and_belongs_to_many :cohort_imports

  enum :contact_method_type,
       { any: "any", other: "other", text: "text", voice: "voice" },
       prefix: :contact_method,
       validate: {
         allow_nil: true
       }

  encrypts :email, :full_name, :phone, :relationship_other, deterministic: true
  encrypts :contact_method_other_details

  normalizes :phone, with: -> { _1.blank? ? nil : _1.to_s.gsub(/\s/, "") }
  normalizes :email, with: -> { _1.blank? ? nil : _1.to_s.downcase.strip }

  validates :full_name, presence: true
  validates :phone,
            presence: {
              if: :phone_receive_updates
            },
            phone: {
              allow_blank: true
            }
  validates :email, presence: true, notify_safe_email: true
  validates :contact_method_other_details,
            :email,
            :full_name,
            :phone,
            length: {
              maximum: 300
            }
  validates :contact_method_other_details,
            presence: true,
            if: :contact_method_other?

  def relationship_to(patient:)
    parent_relationships.find { _1.patient == patient }
  end

  def contact_method_description
    if contact_method_other?
      "Other – #{contact_method_other_details}"
    else
      human_enum_name(:contact_method_type)
    end
  end

  private

  def reset_unused_fields
    self.contact_method_type = nil if phone.blank?
    self.contact_method_other_details = nil unless contact_method_other?
  end
end
