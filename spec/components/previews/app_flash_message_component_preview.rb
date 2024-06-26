# frozen_string_literal: true

class AppFlashMessageComponentPreview < ViewComponent::Preview
  def success
    render AppFlashMessageComponent.new(
             flash: {
               success: {
                 heading: "Record saved for John Smith",
                 body:
                   ActionController::Base.helpers.link_to(
                     "View child record",
                     "https://example.com"
                   )
               }
             }
           )
  end
end
