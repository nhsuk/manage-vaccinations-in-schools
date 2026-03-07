# frozen_string_literal: true

describe CIS2Info do
  let(:cis2_info) do
    described_class.new(
      request_session: {
        "cis2_info" => {
          "role_code" => role_code,
          "activity_codes" => activity_codes
        }
      }
    )
  end

  let(:activity_codes) { [] }

  describe "#is_nurse?" do
    subject { cis2_info.is_nurse? }

    %w[S8000:G8000:R8001 S8000:G8000:R8003].each do |role|
      context "with role code #{role}" do
        let(:role_code) { role }

        it { should be(true) }
      end
    end

    context "with a medical secretary role code" do
      let(:role_code) { "S8000:G8001:R8006" }

      it { should be(false) }
    end
  end

  describe "#is_medical_secretary?" do
    subject { cis2_info.is_medical_secretary? }

    %w[S8000:G8001:R8006 S8001:G8002:R8008].each do |role|
      context "with role code #{role}" do
        let(:role_code) { role }

        it { should be(true) }
      end
    end

    context "with a nurse role code" do
      let(:role_code) { "S8000:G8000:R8001" }

      it { should be(false) }
    end
  end

  describe "#is_healthcare_assistant?" do
    subject { cis2_info.is_healthcare_assistant? }

    let(:activity_codes) { ["B0428"] }

    %w[S8000:G8001:R8006 S8001:G8002:R8008].each do |role|
      context "with role code #{role}" do
        let(:role_code) { role }

        it { should be(true) }
      end
    end

    context "with a non-healthcare assistant role code" do
      let(:role_code) { "S8000:G8000:R8001" }

      it { should be(false) }
    end
  end

  describe "#is_support?" do
    subject { cis2_info.is_support? }

    let(:role_code) { CIS2Info::SUPPORT_ROLE }

    context "with PII access activity codes" do
      let(:activity_codes) do
        [
          CIS2Info::ACCESS_SENSITIVE_FLAGGED_RECORDS_ACTIVITY_CODE,
          CIS2Info::VIEW_DETAILED_HEALTH_RECORDS_ACTIVITY_CODE
        ]
      end

      it { should be(true) }
    end

    context "without PII access activity codes" do
      let(:activity_codes) do
        [
          CIS2Info::VIEW_SHARED_NON_PATIENT_IDENTIFIABLE_INFORMATION_ACTIVITY_CODE
        ]
      end

      it { should be(true) }
    end

    context "with a non-support role code" do
      let(:role_code) { "S8000:G8000:R8001" }
      let(:activity_codes) do
        [
          CIS2Info::VIEW_SHARED_NON_PATIENT_IDENTIFIABLE_INFORMATION_ACTIVITY_CODE
        ]
      end

      it { should be(false) }
    end
  end

  describe "#is_support_without_pii_access?" do
    subject { cis2_info.is_support_without_pii_access? }

    let(:role_code) { CIS2Info::SUPPORT_ROLE }

    context "with non-PII activity code" do
      let(:activity_codes) do
        [
          CIS2Info::VIEW_SHARED_NON_PATIENT_IDENTIFIABLE_INFORMATION_ACTIVITY_CODE
        ]
      end

      it { should be(true) }
    end

    context "without non-PII activity code" do
      let(:activity_codes) { [] }

      it { should be(false) }
    end

    context "with a non-support role code" do
      let(:role_code) { "S8000:G8000:R8001" }
      let(:activity_codes) do
        [
          CIS2Info::VIEW_SHARED_NON_PATIENT_IDENTIFIABLE_INFORMATION_ACTIVITY_CODE
        ]
      end

      it { should be(false) }
    end
  end

  describe "#is_support_with_pii_access?" do
    subject { cis2_info.is_support_with_pii_access? }

    let(:role_code) { CIS2Info::SUPPORT_ROLE }

    context "with PII access activity codes" do
      let(:activity_codes) do
        [
          CIS2Info::ACCESS_SENSITIVE_FLAGGED_RECORDS_ACTIVITY_CODE,
          CIS2Info::VIEW_DETAILED_HEALTH_RECORDS_ACTIVITY_CODE
        ]
      end

      it { should be(true) }
    end

    context "with only one PII activity code" do
      let(:activity_codes) do
        [CIS2Info::ACCESS_SENSITIVE_FLAGGED_RECORDS_ACTIVITY_CODE]
      end

      it { should be(false) }
    end

    context "with a non-support role code" do
      let(:role_code) { "S8000:G8000:R8001" }
      let(:activity_codes) do
        [
          CIS2Info::ACCESS_SENSITIVE_FLAGGED_RECORDS_ACTIVITY_CODE,
          CIS2Info::VIEW_DETAILED_HEALTH_RECORDS_ACTIVITY_CODE
        ]
      end

      it { should be(false) }
    end
  end
end
