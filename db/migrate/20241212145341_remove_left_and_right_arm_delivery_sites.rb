# frozen_string_literal: true

class RemoveLeftAndRightArmDeliverySites < ActiveRecord::Migration[8.0]
  def change
    VaccinationRecord.where(delivery_site: 0).update_all(delivery_site: 2)
    VaccinationRecord.where(delivery_site: 1).update_all(delivery_site: 4)
  end
end
