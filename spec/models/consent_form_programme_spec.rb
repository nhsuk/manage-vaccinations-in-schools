# frozen_string_literal: true

# == Schema Information
#
# Table name: consent_form_programmes
#
#  id                 :bigint           not null, primary key
#  notes              :text             default(""), not null
#  programme_type     :enum             not null
#  reason_for_refusal :integer
#  response           :integer
#  vaccine_methods    :integer          default([]), not null, is an Array
#  without_gelatine   :boolean
#  consent_form_id    :bigint           not null
#
# Indexes
#
#  idx_on_programme_type_consent_form_id_805eb5d685  (programme_type,consent_form_id) UNIQUE
#  index_consent_form_programmes_on_consent_form_id  (consent_form_id)
#
# Foreign Keys
#
#  fk_rails_...  (consent_form_id => consent_forms.id) ON DELETE => cascade
#
describe ConsentFormProgramme do
  let(:programme) { Programme.mmr }
  let(:session) { create(:session, programmes: [programme]) }
  let(:consent_form) { create(:consent_form, :given, session:) }
  let(:consent_form_programme) { consent_form.consent_form_programmes.first }

  describe "#vaccines" do
    context "when there are MMR and MMRV vaccines" do
      it "only returns MMR vaccines" do
        expect(consent_form_programme.vaccines).to match_array(
          programme.vaccines
        )
      end
    end
  end
end
