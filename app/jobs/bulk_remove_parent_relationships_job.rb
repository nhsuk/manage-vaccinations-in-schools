# frozen_string_literal: true

class BulkRemoveParentRelationshipsJob < ApplicationJob
  queue_as :imports

  def perform(import_global_id, consent_ids, user_id, remove_option)
    import = GlobalID::Locator.locate(import_global_id)
    consents = Consent.where(id: consent_ids)

    if remove_option == "unconsented_only"
      import.destroy_parent_relationships_without_consent!(consents)
    else
      import.destroy_parent_relationships_and_invalidate_consents!(
        User.find(user_id),
        consents
      )
    end

    import.update!(status: :processed)
  end
end
