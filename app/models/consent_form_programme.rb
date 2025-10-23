# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_form_programmes
#
#  id                 :bigint           not null, primary key
#  notes              :text             default(""), not null
#  reason_for_refusal :integer
#  response           :integer
#  vaccine_methods    :integer          default([]), not null, is an Array
#  without_gelatine   :boolean
#  consent_form_id    :bigint           not null
#  programme_id       :bigint           not null
#
# Indexes
#
#  idx_on_programme_id_consent_form_id_2113cb7f37    (programme_id,consent_form_id) UNIQUE
#  index_consent_form_programmes_on_consent_form_id  (consent_form_id)
#
# Foreign Keys
#
#  fk_rails_...  (consent_form_id => consent_forms.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id) ON DELETE => cascade
#
class ConsentFormProgramme < ApplicationRecord
  include HasVaccineMethods
  include Refusable

  belongs_to :consent_form
  belongs_to :programme

  scope :ordered, -> { joins(:programme).order(:"programme.type") }

  enum :response, { given: 0, refused: 1 }, prefix: true

  delegate :flu?, :hpv?, :menacwy?, :mmr?, :td_ipv?, to: :programme

  def vaccines
    VaccineCriteria.from_consentable(self).apply(
      Vaccine.active.where(programme_id:)
    )
  end

  def human_enum_name(attribute)
    Consent.human_enum_name(attribute, send(attribute))
  end

  private

  def requires_reason_for_refusal? = false
end
