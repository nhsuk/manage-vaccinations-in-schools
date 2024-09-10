# frozen_string_literal: true

# == Schema Information
#
# Table name: parents
#
#  id                   :bigint           not null, primary key
#  contact_method       :integer
#  contact_method_other :text
#  email                :string
#  name                 :string
#  phone                :string
#  recorded_at          :datetime
#  relationship         :integer
#  relationship_other   :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class Parent < ApplicationRecord
  include Recordable

  audited

  before_save :reset_unused_fields

  has_one :patient

  has_and_belongs_to_many :cohort_imports

  attr_accessor :parental_responsibility

  enum :contact_method, %w[text voice other any], prefix: true
  enum :relationship, %w[mother father guardian other], prefix: true

  encrypts :email, :name, :phone, :relationship_other

  validates :name, presence: true
  validates :phone, phone: true, if: -> { phone.present? }
  validates :email, presence: true, notify_safe_email: true
  validates :relationship, inclusion: { in: Parent.relationships.keys }
  validates :relationship_other, presence: true, if: -> { relationship_other? }
  validate :has_parental_responsibility, if: -> { relationship_other? }
  validates :contact_method_other,
            :email,
            :name,
            :phone,
            :relationship_other,
            length: {
              maximum: 300
            }
  validates :contact_method_other, presence: true, if: :contact_method_other?

  def relationship_label
    if relationship == "other"
      relationship_other
    else
      human_enum_name(:relationship)
    end.capitalize
  end

  def phone_contact_method_description
    if contact_method_other.present?
      "Other – #{contact_method_other}"
    else
      human_enum_name(:contact_method)
    end
  end

  def phone=(str)
    super str.blank? ? nil : str.to_s.gsub(/\s/, "")
  end

  def email=(str)
    super str.nil? ? nil : str.to_s.downcase.strip
  end

  def has_parental_responsibility
    return if parental_responsibility == "yes"
    if parental_responsibility == "no" && validation_context != :manage_consent
      return
    end

    if validation_context == :manage_consent
      errors.add(:parental_responsibility, :inclusion)
    else
      errors.add(:parental_responsibility, :inclusion_on_consent_form)
    end
  end

  private

  def reset_unused_fields
    if phone.blank?
      self.contact_method = nil
      self.contact_method_other = nil
    end

    self.relationship_other = nil if relationship != "other"
  end
end
