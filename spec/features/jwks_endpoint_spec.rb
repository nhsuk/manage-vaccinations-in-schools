# frozen_string_literal: true

describe "JWKS endpoint" do
  scenario "Getting keys" do
    when_we_retrieve_the_jwks
    then_i_see_a_key
  end

  def when_we_retrieve_the_jwks
    visit "/oidc/jwks"
  end

  def then_i_see_a_key
    jwks = JSON.parse(page.body)
    expect(jwks["keys"].count).to eq 1
  end
end
