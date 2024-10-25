# frozen_string_literal: true

# == Schema Information
#
# Table name: notify_log_entries
#
#  id              :bigint           not null, primary key
#  recipient       :string           not null
#  type            :integer          not null
#  created_at      :datetime         not null
#  consent_form_id :bigint
#  patient_id      :bigint
#  template_id     :string           not null
#
# Indexes
#
#  index_notify_log_entries_on_consent_form_id  (consent_form_id)
#  index_notify_log_entries_on_patient_id       (patient_id)
#
# Foreign Keys
#
#  fk_rails_...  (consent_form_id => consent_forms.id)
#  fk_rails_...  (patient_id => patients.id)
#
describe NotifyLogEntry do
  subject(:notify_log_entry) { build(:notify_log_entry, type) }

  context "with an email type" do
    let(:type) { :email }

    it { should be_valid }
  end

  context "with an SMS type" do
    let(:type) { :sms }

    it { should be_valid }
  end
end
