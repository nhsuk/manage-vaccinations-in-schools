class AppFlashSuccessComponent < ViewComponent::Base
  attr_reader :body, :title

  def initialize(flash_success)
    super

    if flash_success.is_a?(Hash)
      @body = flash_success["body"]
      @title = flash_success["title"]
    else
      @body = flash_success
      @title = nil
    end
  end
end
