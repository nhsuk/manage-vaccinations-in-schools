module RedirectHelper
  def without_following_redirects &block
    begin
      options = page.driver.instance_variable_get(:@options)
      prev_value = options[:follow_redirects]
      options[:follow_redirects] = false

      yield
    ensure
      options[:follow_redirects] = prev_value
    end
  end

  def then_i_am_redirected_to(url)
    expect(page.driver.browser.current_url).to eq(url)
  end

  def mavis_reporting_app_url(path='/')
    root = Settings.mavis_reporting_app.root_url || 'http://localhost:5000/'
    URI.join(root, path).to_s
  end
end