# frozen_string_literal: true

describe "mavis vaccination-records bulk_edit" do
  let(:programme) { CachedProgramme.hpv }
  let(:vaccination_records) do
    create_list(
      :vaccination_record,
      2,
      :sourced_from_nhs_immunisations_api,
      programme:
    )
  end

  it "updates multiple records from CSV via edit command" do
    Tempfile.create(%w[bulk .csv]) do |file|
      file.write(
        "id,uuid,nhs_immunisations_api_primary_source,nhs_immunisations_api_id\n"
      )
      file.write(
        "#{vaccination_records.first.id},#{SecureRandom.uuid},false,#{SecureRandom.uuid}\n"
      )
      file.write(
        "#{vaccination_records.second.id},#{SecureRandom.uuid},false,#{SecureRandom.uuid}\n"
      )
      file.flush

      output =
        capture_output do
          Dry::CLI.new(MavisCLI).call(
            arguments: ["vaccination-records", "bulk-edit", "--file", file.path]
          )
        end

      expect(output).to include("Successfully updated VaccinationRecord").twice
    end
  end

  it "accepts raw CSV content via --csv option" do
    csv = <<~CSV
      id,uuid,nhs_immunisations_api_primary_source
      #{vaccination_records.first.id},#{SecureRandom.uuid},true
      #{vaccination_records.second.id},#{SecureRandom.uuid},false
    CSV

    output =
      capture_output do
        Dry::CLI.new(MavisCLI).call(
          arguments: ["vaccination-records", "bulk-edit", "--csv", csv]
        )
      end

    expect(output).to include("Successfully updated VaccinationRecord").twice
  end

  def capture_output
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end
end
