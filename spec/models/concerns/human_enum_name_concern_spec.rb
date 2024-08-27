# frozen_string_literal: true

describe HumanEnumNameConcern do
  let(:dummy_class) do
    Class.new do
      include HumanEnumNameConcern

      attr_reader :status

      def initialize(status:)
        @status = status
      end

      def self.model_name
        ActiveModel::Name.new(self, nil, "Dummy")
      end

      def [](attr)
        send(attr)
      end
    end
  end

  describe ".human_enum_name" do
    subject { dummy_class.human_enum_name(enum_name, enum_value) }

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
              dummy: {
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

    context "when attribute value is blank" do
      before do
        I18n.backend.store_translations(
          :en,
          activerecord: {
            attributes: {
              dummy: {
                statuses: {
                  test_status: "Test status"
                }
              }
            }
          }
        )
      end

      let(:enum_value) { nil }

      it { should eq "" }
    end
  end

  describe "#human_enum_name" do
    subject(:record) do
      dummy_class.new(status: :test_status).human_enum_name(:status)
    end

    before do
      allow(dummy_class).to receive(:human_enum_name).and_return("Test status")
    end

    # Cannot instantiate ActiveRecord
    it { should eq "Test status" }
  end
end
