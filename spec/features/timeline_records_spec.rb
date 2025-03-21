# frozen_string_literal: true

describe "TimelineRecords UI" do
  before do
    create(:session, id: 1)
    create(:patient, id: 1, session: Session.first)
  end

  scenario "Endpoint doesn't exist in prod" do
    given_i_am_in_production

    when_i_visit_the_timeline_endpoint
    then_i_should_see_a_404_error
  end

  scenario "Endpoint is rendered in test" do
    given_i_am_in_test

    when_i_visit_the_timeline_endpoint
    then_i_should_see_the_page_rendered
  end

  def given_i_am_in_production
    allow(Rails).to receive(:env).and_return("production".inquiry)
  end

  def given_i_am_in_test
    # Already implicitly in test
  end

  def when_i_visit_the_timeline_endpoint
    visit "/inspect/timeline/patients/1"
  end

  def then_i_should_see_a_404_error
    expect(page.html).to include(
      "If you entered a web address, check it is correct."
    )
  end

  def then_i_should_see_the_page_rendered
    expect(page.status_code).to eq(200)
    expect(page.html).to include("Inspect Patient 1")
  end
end
