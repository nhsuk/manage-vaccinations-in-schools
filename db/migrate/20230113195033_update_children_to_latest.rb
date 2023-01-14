
class UpdateChildrenToLatest < ActiveRecord::Migration[7.0]
  def change
    # Do not run this migration on production or existing data, as it is a
    # destructive migration. Remove child records before running.
    raise "Child records exist, cannot run migration" if Child.any?

    change_table :children do |t|
      t.integer :sex
      t.full_name :name
      t.text :first_name
      t.text :last_name
      t.text :preferred_name
      t.integer :gp
      t.integer :screening
      t.integer :consent
      t.integer :seen
    end
  end
end
