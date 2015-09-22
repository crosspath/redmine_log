class AddDurationToLogs < ActiveRecord::Migration
  def change
    change_table :logs do |t|
      t.float :duration
    end
  end
end
