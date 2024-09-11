# frozen_string_literal: true

class ChangeTeamReplyToIdToUuid < ActiveRecord::Migration[7.2]
  def up
    uuid_regex =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/

    Team
      .where.not(reply_to_id: nil)
      .reject { uuid_regex.match?(_1.reply_to_id.downcase) }
      .each { _1.update!(reply_to_id: nil) }

    change_column :teams, :reply_to_id, :uuid, using: "reply_to_id::uuid"
  end

  def down
    change_column :teams, :reply_to_id, :string
  end
end
