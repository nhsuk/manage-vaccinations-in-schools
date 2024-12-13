# frozen_string_literal: true

class AddDataSharingAgreementUrlToOrganisations < ActiveRecord::Migration[8.0]
  def up
    add_column :organisations, :privacy_notice_url, :string
    Organisation.update_all(
      privacy_notice_url: "https://example.com/privacy-notice"
    )
    change_column_null :organisations, :privacy_notice_url, false
  end

  def down
    remove_column :organisations, :privacy_notice_url, :string
  end
end
