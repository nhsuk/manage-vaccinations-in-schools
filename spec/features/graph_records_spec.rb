# frozen_string_literal: true

describe "GraphRecord UI" do
  scenario "Endpoint doesn't exist in prod" do
    given_i_am_in_production

    when_i_visit_the_graph_endpoint
    then_i_should_see_a_404_error
  end

  scenario "Endpoint is rendered in test" do
    given_i_am_in_test
    given_a_patient_exists

    when_i_visit_the_graph_endpoint
    then_i_should_see_the_page_rendered
  end

  def given_i_am_in_production
    allow(Rails).to receive(:env).and_return("production".inquiry)
  end

  def given_i_am_in_test
    # Already implicitly in test
  end

  def given_a_patient_exists
    create(:patient, id: 1)
  end

  def when_i_visit_the_graph_endpoint
    visit "/inspect/graph/patient/1"
  end

  def then_i_should_see_a_404_error
    expect(page.status_code).to eq(404)
  end

  def then_i_should_see_the_page_rendered
    expect(page.status_code).to eq(200)
    expect(page.html).to include("Inspect patient 1")
  end
end
