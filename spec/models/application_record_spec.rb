require "rails_helper"

RSpec.describe ApplicationRecord do
  describe ".human_enum_name" do
    subject { described_class.human_enum_name(enum_name, enum_value) }

    let(:enum_name) { :status }
    let(:enum_value) { :test_status }

    context "when no translation is available" do
      it { should eq "Test status" }
    end

    context "when a translation is available" do
      before do
        I18n.backend.store_translations(
          :en,
          activerecord: {
            attributes: {
              application_record: {
                statuses: {
                  test_status: "Test status"
                }
              }
            }
          }
        )
      end

      it { should eq "Test status" }
    end
  end
end
