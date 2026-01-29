# frozen_string_literal: true

class BulkRemoveParentRelationshipsJob < ApplicationJob
  queue_as :imports

  def perform(
    import_global_id,
    parent_relationship_ids_to_remove,
    all_consent_ids,
    user_id,
    remove_option
  )
    import = GlobalID::Locator.locate(import_global_id)
    user = User.find(user_id)
    consents = Consent.where(id: all_consent_ids)

    ActiveRecord::Base.transaction do
      parent_relationships =
        import
          .parent_relationships
          .where(id: parent_relationship_ids_to_remove)
          .includes(:parent, :patient)

      if remove_option == "all"
        invalidate_consents!(parent_relationships, user, consents)
      end

      parents_to_check = parent_relationships.map(&:parent)
      patient_ids = parent_relationships.pluck(:patient_id)

      parent_relationships.destroy_all

      parents_to_check.each do |parent|
        next if parent.destroyed?
        next if parent.parent_relationships.exists?
        next if parent.consents.exists?

        parent.destroy!
      end

      StatusUpdaterJob.perform_bulk(patient_ids.zip)
    end

    mark_complete_if_finished(import, remove_option, consents)
  end

  private

  def invalidate_consents!(parent_relationships, user, consents)
    consents_to_invalidate =
      consents.where(
        patient_id: parent_relationships.select(:patient_id),
        parent_id: parent_relationships.select(:parent_id)
      )

    return if consents_to_invalidate.empty?

    timestamp = Time.current.to_fs(:long)
    invalidation_note =
      "Consent invalidated on #{timestamp} " \
        "because #{user.full_name} removed all parent-child relationships from an import."

    consents_to_invalidate.update_all(
      notes: invalidation_note,
      invalidated_at: Time.current
    )
  end

  def mark_complete_if_finished(import, remove_option, consents)
    remaining_ids =
      if remove_option == "unconsented_only"
        import.parent_relationship_ids -
          consents.map(&:parent_relationship).compact.pluck(:id)
      else
        import.parent_relationship_ids
      end

    return if remaining_ids.any?

    import.update!(status: :processed)
  end
end
