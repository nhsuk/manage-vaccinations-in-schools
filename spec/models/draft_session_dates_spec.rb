# frozen_string_literal: true

describe DraftSessionDates do
  subject(:draft_session_dates) do
    described_class.new(
      request_session: request_session,
      current_user: current_user,
      session: session,
      wizard_step: :dates
    )
  end

  let(:programme) { create(:programme, :hpv) }
  let(:team) { create(:team, :with_one_nurse, programmes: [programme]) }
  let(:session) { create(:session, team: team, programmes: [programme]) }
  let(:current_user) { team.users.first }
  let(:request_session) { {} }

  describe "validations" do
    context "with valid session dates" do
      before do
        draft_session_dates.session_dates_attributes = {
          "0" => {
            "value(1i)" => "2024",
            "value(2i)" => "10",
            "value(3i)" => "15"
          }
        }
      end

      it "is valid" do
        expect(draft_session_dates.valid?(:update)).to be true
      end
    end

    context "with invalid date" do
      before do
        draft_session_dates.session_dates_attributes = {
          "0" => {
            "value(1i)" => "2024",
            "value(2i)" => "13", # Invalid month
            "value(3i)" => "15"
          }
        }
      end

      it "is invalid" do
        expect(draft_session_dates.valid?(:update)).to be false
        expect(draft_session_dates.errors[:base]).to include(
          "Enter a valid date"
        )
      end
    end

    context "with duplicate dates" do
      before do
        draft_session_dates.session_dates_attributes = {
          "0" => {
            "value(1i)" => "2024",
            "value(2i)" => "10",
            "value(3i)" => "15"
          },
          "1" => {
            "value(1i)" => "2024",
            "value(2i)" => "10",
            "value(3i)" => "15"
          }
        }
      end

      it "is invalid" do
        expect(draft_session_dates.valid?(:update)).to be false
        expect(draft_session_dates.errors[:base]).to include(
          "Session dates must be unique"
        )
      end

      it "validates uniqueness of dates" do
        # First validate to trigger the validation
        draft_session_dates.valid?(:update)

        # Check that the validation was triggered
        expect(draft_session_dates.errors[:base]).to include(
          "Session dates must be unique"
        )

        # Now change one of the dates to make them unique
        draft_session_dates.session_dates_attributes = {
          "0" => {
            "value(1i)" => "2024",
            "value(2i)" => "10",
            "value(3i)" => "15"
          },
          "1" => {
            "value(1i)" => "2024",
            "value(2i)" => "10",
            "value(3i)" => "16" # Changed day from 15 to 16
          }
        }

        # Validate again
        expect(draft_session_dates.valid?(:update)).to be true
      end
    end

    context "with no dates" do
      before { draft_session_dates.session_dates_attributes = {} }

      it "is invalid on update" do
        expect(draft_session_dates.valid?(:update)).to be false
        expect(draft_session_dates.errors[:base]).to include("Enter a date")
      end

      it "is valid on create (allows saving empty draft)" do
        expect(draft_session_dates.valid?(:create)).to be true
      end
    end
  end

  describe "#write_to!" do
    let(:target_session) do
      create(:session, team: team, programmes: [programme])
    end

    before do
      draft_session_dates.session = target_session
      draft_session_dates.session_dates_attributes = {
        "0" => {
          "value(1i)" => "2024",
          "value(2i)" => "10",
          "value(3i)" => "15"
        }
      }
    end

    it "creates new session dates" do
      expect { draft_session_dates.write_to!(target_session) }.to change {
        target_session.session_dates.count
      }.by(1)

      expect(target_session.session_dates.last.value).to eq(
        Date.new(2024, 10, 15)
      )
    end

    it "calls set_notification_dates on the session" do
      expect(target_session).to receive(:set_notification_dates)
      expect(target_session).to receive(:save!)

      draft_session_dates.write_to!(target_session)
    end
  end

  describe "#parse_date_from_attributes" do
    it "parses date from multi-parameter attributes" do
      attrs = {
        "value(1i)" => "2024",
        "value(2i)" => "10",
        "value(3i)" => "15"
      }

      result = draft_session_dates.send(:parse_date_from_attributes, attrs)
      expect(result).to eq(Date.new(2024, 10, 15))
    end

    it "returns nil for invalid date" do
      attrs = {
        "value(1i)" => "2024",
        "value(2i)" => "13", # Invalid month
        "value(3i)" => "15"
      }

      result = draft_session_dates.send(:parse_date_from_attributes, attrs)
      expect(result).to be_nil
    end

    it "returns date object as-is" do
      date = Date.new(2024, 10, 15)
      attrs = { "value" => date }

      result = draft_session_dates.send(:parse_date_from_attributes, attrs)
      expect(result).to eq(date)
    end
  end
end
