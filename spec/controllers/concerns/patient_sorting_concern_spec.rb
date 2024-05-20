require "rails_helper"

describe PatientSortingConcern do
  let(:klass) do
    Class.new do
      include PatientSortingConcern
      attr_accessor :params

      def initialize(params)
        @params = params
      end
    end
  end

  subject { klass.new(params) }

  let(:alex) do
    create(:patient, first_name: "Alex", date_of_birth: "2010-01-01")
  end
  let(:blair) do
    create(:patient, first_name: "Blair", date_of_birth: "2010-01-02")
  end
  let(:casey) do
    create(:patient, first_name: "Casey", date_of_birth: "2010-01-03")
  end

  let(:patient_sessions) do
    [
      create(:patient_session, :added_to_session, patient: alex),
      create(:patient_session, :delay_vaccination, patient: blair),
      create(:patient_session, :vaccinated, patient: casey)
    ]
  end

  describe "#sort_patients!" do
    context "when sort parameter is 'name' ascending" do
      let(:params) { { sort: "name", direction: "asc" } }

      it "sorts patient sessions by name in ascending order" do
        subject.sort_patients!(patient_sessions)
        expect(patient_sessions.map(&:patient).map(&:first_name)).to eq(
          %w[Alex Blair Casey]
        )
      end
    end

    context "when sort parameter is 'dob' descending" do
      let(:params) { { sort: "dob", direction: "desc" } }

      it "sorts patient sessions by date of birth in descending order" do
        subject.sort_patients!(patient_sessions)
        expect(patient_sessions.map(&:patient).map(&:first_name)).to eq(
          %w[Casey Blair Alex]
        )
      end
    end

    context "when sort parameter is 'outcome'" do
      let(:params) { { sort: "outcome", direction: "desc" } }

      it "sorts patient sessions by state in descending order" do
        subject.sort_patients!(patient_sessions)
        expect(patient_sessions.map(&:state)).to eq(
          %w[vaccinated delay_vaccination added_to_session]
        )
      end
    end

    context "when sort parameter is missing" do
      let(:params) { {} }

      it "does not change the order of patient sessions" do
        subject.sort_patients!(patient_sessions)
        expect(patient_sessions.map(&:patient).map(&:first_name)).to eq(
          %w[Alex Blair Casey]
        )
      end
    end
  end
end
