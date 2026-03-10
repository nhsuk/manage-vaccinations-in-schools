# frozen_string_literal: true

class Schools::ImportController < Schools::BaseController
  def new
    draft_import = DraftImport.new(request_session: session, current_user:)

    draft_import.clear_attributes
    draft_import.update!(location: @location, type: "class")

    steps = draft_import.wizard_steps
    steps.delete(:type)
    steps.delete(:location)

    redirect_to draft_import_path(I18n.t(steps.first, scope: :wicked))
  end
end
