# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_form_programmes
#
#  id              :bigint           not null, primary key
#  response        :integer
#  vaccine_methods :integer          default([]), not null, is an Array
#  consent_form_id :bigint           not null
#  programme_id    :bigint           not null
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

  belongs_to :consent_form
  belongs_to :programme

  scope :ordered, -> { joins(:programme).order(:"programme.type") }

  enum :response, { given: 0, refused: 1 }, prefix: true

  def vaccines
    vaccine_methods.flat_map do |method|
      Vaccine.active.where(programme_id:, method:)
    end
  end
end
