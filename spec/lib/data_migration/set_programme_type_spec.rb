# frozen_string_literal: true

describe DataMigration::SetProgrammeType do
  subject(:call) { described_class.call }

  context "with a vaccination record" do
    let(:programme) { CachedProgramme.hpv }
    let(:vaccination_record) do
      create(:vaccination_record, programme:, programme_type: nil)
    end

    it "sets the programme type" do
      expect { call }.to change {
        vaccination_record.reload.programme_type
      }.from(nil).to("hpv")
    end
  end

  context "with a team" do
    let(:flu_programme) { CachedProgramme.flu }
    let(:hpv_programme) { CachedProgramme.hpv }

    let(:team) do
      create(:team, programmes: [flu_programme, hpv_programme]).tap do
        it.update_column(:programme_types, nil)
      end
    end

    it "sets the programme types" do
      expect { call }.to change { team.reload.programme_types }.from(nil).to(
        %w[flu hpv]
      )
    end
  end

  context "with a notify log entry" do
    let(:flu_programme) { CachedProgramme.flu }
    let(:hpv_programme) { CachedProgramme.hpv }

    let(:notify_log_entry) do
      create(
        :notify_log_entry,
        :sms,
        programme_ids: [flu_programme.id, hpv_programme.id],
        programme_types: nil
      )
    end

    it "sets the programme types" do
      expect { call }.to change {
        notify_log_entry.reload.programme_types
      }.from(nil).to(%w[flu hpv])
    end
  end
end
