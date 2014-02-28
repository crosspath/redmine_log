class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.string :method
      t.string :query
      t.string :parameters
      t.references :user
      t.integer :response_code
      t.timestamps
    end
  end
end
