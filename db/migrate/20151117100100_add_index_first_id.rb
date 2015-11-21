class AddIndexFirstId < ActiveRecord::Migration
  def change
    add_index :logs, :first_id
  end
end
