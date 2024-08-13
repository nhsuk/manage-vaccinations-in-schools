# frozen_string_literal: true

class MESHValidateMailboxJob < ApplicationJob
  queue_as :mesh

  def perform
    MESH.validate_mailbox if Flipper.enabled? :mesh_jobs
  end
end
