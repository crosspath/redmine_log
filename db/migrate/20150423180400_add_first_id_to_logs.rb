class AddFirstIdToLogs < ActiveRecord::Migration
  def change
    change_table :logs do |t|
      t.integer :first_id
    end
  end
end
