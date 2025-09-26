# frozen_string_literal: true

describe AppSessionDatesTableComponent do
  subject(:rendered) { render_inline(component) }

  let(:flu_injection_vaccine) { build(:vaccine, :cell_based_trivalent) }
  let(:flu_nasal_vaccine) { build(:vaccine, :fluenz) }
  let(:hpv_programme) { create(:programme, :hpv) }
  let(:flu_programme) do
    create(
      :programme,
      :flu,
      vaccines: [flu_injection_vaccine, flu_nasal_vaccine]
    )
  end
  let(:session) { create(:session, programmes: [hpv_programme, flu_programme]) }
  let(:session_date_today) { session.session_dates.first }
  let(:location) { session.location }

  let(:component) { described_class.new(session) }

  context "with session in progress but no vaccinations" do
    it "displays zero tallies for all programmes" do
      session_date_today =
        session.session_dates.first.value.strftime("%e %B %Y")

      rendered

      expect_tally(session_date_today, "Flu (nasal spray)", 0)
      expect_tally(session_date_today, "Flu (injection)", 0)
      expect_tally("Total", "Flu (nasal spray)", 0)
      expect_tally("Total", "Flu (injection)", 0)

      expect_tally(session_date_today, "HPV", 0)
      expect_tally("Total", "HPV", 0)
    end
  end

  context "multiple session dates with vaccinations for Flu and HPV" do
    let(:session_date_yesterday) { Date.yesterday }

    before do
      session.session_dates.create!(value: session_date_yesterday)

      create(
        :vaccination_record,
        session:,
        programme: hpv_programme,
        performed_at: session_date_yesterday,
        patient: create(:patient, session:, year_group: 9)
      )

      create(
        :vaccination_record,
        session:,
        programme: flu_programme,
        performed_at: session_date_today.value,
        patient: create(:patient, session:, year_group: 9),
        vaccine: flu_injection_vaccine
      )

      create(
        :vaccination_record,
        session:,
        programme: flu_programme,
        performed_at: session_date_today.value,
        patient: create(:patient, session:, year_group: 9),
        vaccine: flu_injection_vaccine
      )

      create(
        :vaccination_record,
        session:,
        programme: flu_programme,
        performed_at: session_date_today.value,
        patient: create(:patient, session:, year_group: 9),
        vaccine: flu_nasal_vaccine
      )
    end

    it "displays the correct tallies" do
      session_date_today_formatted =
        session_date_today.value.strftime("%e %B %Y")
      session_date_yesterday_formatted =
        session_date_yesterday.strftime("%e %B %Y")

      rendered

      expect_tally(session_date_yesterday_formatted, "HPV", 1)
      expect_tally("Total", "HPV", 1)

      expect_tally(session_date_today_formatted, "Flu (injection)", 2)
      expect_tally(session_date_today_formatted, "Flu (nasal spray)", 1)
      expect_tally("Total", "Flu (nasal spray)", 1)
      expect_tally("Total", "Flu (injection)", 2)
    end
  end

  def expect_tally(session_date_today, column_name, count)
    table = page.find("table.nhsuk-table-responsive")

    # puts(table.native.to_html)

    row = table.find("tr", text: session_date_today)
    headers = table.all("th").map(&:text)
    column_index = headers.index(column_name)

    expect(column_index).not_to be_nil,
    "Column '#{column_name}' not found in headers: #{headers}"

    cells = row.all("td")
    cell_value =
      cells[column_index].text.strip.gsub(/\A\s*/, "").gsub(/\s*\z/, "")

    expect(cell_value).to eq(count.to_s),
    "Expected #{column_name} for #{session_date_today} to be #{count} but got #{cell_value}"
  end
end
