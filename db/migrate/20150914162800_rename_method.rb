class RenameMethod < ActiveRecord::Migration
  def change
    rename_column :logs, :method, :http_method
  end
end
