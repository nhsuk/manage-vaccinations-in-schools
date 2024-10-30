# frozen_string_literal: true

# == Schema Information
#
# Table name: organisation_programmes
#
#  id              :bigint           not null, primary key
#  organisation_id :bigint           not null
#  programme_id    :bigint           not null
#
# Indexes
#
#  idx_on_organisation_id_programme_id_892684ca8e    (organisation_id,programme_id) UNIQUE
#  index_organisation_programmes_on_organisation_id  (organisation_id)
#  index_organisation_programmes_on_programme_id     (programme_id)
#
# Foreign Keys
#
#  fk_rails_...  (organisation_id => organisations.id)
#  fk_rails_...  (programme_id => programmes.id)
#
class OrganisationProgramme < ApplicationRecord
  audited

  belongs_to :programme
  belongs_to :organisation
end
