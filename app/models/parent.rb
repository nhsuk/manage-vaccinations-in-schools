# frozen_string_literal: true

# == Schema Information
#
# Table name: parents
#
#  id                           :bigint           not null, primary key
#  contact_method_other_details :text
#  contact_method_type          :string
#  email                        :string
#  name                         :string
#  phone                        :string
#  recorded_at                  :datetime
#  relationship                 :integer
#  relationship_other           :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#
class Parent < ApplicationRecord
  include Recordable

  audited

  before_save :reset_unused_fields

  has_one :patient
  has_many :parent_relationships

  has_and_belongs_to_many :cohort_imports

  attr_accessor :parental_responsibility

  enum :contact_method_type,
       { any: "any", other: "other", text: "text", voice: "voice" },
       prefix: :contact_method,
       validate: {
         allow_nil: true
       }

  enum :relationship,
       %w[mother father guardian other],
       prefix: true,
       validate: true

  encrypts :email, :name, :phone, :relationship_other, deterministic: true
  encrypts :contact_method_other_details

  normalizes :phone,
             with: ->(str) { str.blank? ? nil : str.to_s.gsub(/\s/, "") }
  normalizes :email, with: ->(str) { str.nil? ? nil : str.to_s.downcase.strip }

  validates :name, presence: true
  validates :phone, phone: { allow_blank: true }
  validates :email, presence: true, notify_safe_email: true
  validates :relationship_other, presence: true, if: -> { relationship_other? }
  validate :has_parental_responsibility, if: -> { relationship_other? }
  validates :contact_method_other_details,
            :email,
            :name,
            :phone,
            :relationship_other,
            length: {
              maximum: 300
            }
  validates :contact_method_other_details,
            presence: true,
            if: :contact_method_other?

  def relationship_label
    if relationship == "other"
      relationship_other
    else
      human_enum_name(:relationship)
    end.capitalize
  end

  def contact_method_description
    if contact_method_other?
      "Other – #{contact_method_other_details}"
    else
      human_enum_name(:contact_method_type)
    end
  end

  def has_parental_responsibility
    return if parental_responsibility == "yes"
    return if parental_responsibility == "no"

    errors.add(:parental_responsibility, :inclusion)
  end

  private

  def reset_unused_fields
    self.contact_method_type = nil if phone.blank?

    self.contact_method_other_details = nil unless contact_method_other?

    self.relationship_other = nil if relationship != "other"
  end
end
