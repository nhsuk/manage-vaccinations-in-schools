# frozen_string_literal: true

describe DataMigration::BackfillNotifyLogEntryProgrammes do
  subject(:call) { described_class.call }

  let!(:notify_log_entry) do
    create(:notify_log_entry, :email, programme_types: %w[hpv flu mmr])
  end

  it "creates NotifyLogEntry::Programme records from programme_types" do
    expect { call }.to change(NotifyLogEntry::Programme, :count).by(3)

    expect(
      notify_log_entry.reload.notify_log_entry_programmes
    ).to contain_exactly(
      have_attributes(
        programme_type: "hpv",
        disease_types: %w[human_papillomavirus]
      ),
      have_attributes(programme_type: "flu", disease_types: %w[influenza]),
      have_attributes(
        programme_type: "mmr",
        disease_types: %w[measles mumps rubella]
      )
    )
  end
end
