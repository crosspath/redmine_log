class AddIndexToLogs < ActiveRecord::Migration
  def change
    add_index :logs, :created_at
  end
end
