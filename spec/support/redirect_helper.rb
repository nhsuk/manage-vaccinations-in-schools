# frozen_string_literal: true

module RedirectHelper
  def without_following_redirects
    options = page.driver.instance_variable_get(:@options)
    prev_value = options[:follow_redirects]
    options[:follow_redirects] = false

    yield
  ensure
    options[:follow_redirects] = prev_value
  end

  def then_i_am_redirected_to(url)
    expect(page.driver.browser.current_url).to eq(url)
  end

  def then_i_am_redirected_to_a_url_matching(url_pattern)
    expected_uri = URI(url_pattern)
    current_uri = URI(page.driver.browser.current_url)

    expect(current_uri.path).to eq(expected_uri.path)
    expect(current_uri.host).to eq(expected_uri.host)
    expected_params = Rack::Utils.parse_query(expected_uri.query)
    current_params = Rack::Utils.parse_query(current_uri.query)
    # we may get an extra param, but that's fine in this case
    expect(current_params).to include(expected_params)
  end

  def reporting_app_url(path = "/")
    root =
      Settings.reporting_api.client_app.root_url || "http://localhost:5001/"
    URI.join(root, path).to_s
  end
end
