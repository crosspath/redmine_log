class AddIndexToLogs < ActiveRecord::Migration
  COLS = %w/query parameters referer/
  def up
    COLS.each { |c| change_column :logs, c, :text, limit: 4096 }
  end
  def down
    COLS.each { |c| change_column :logs, c, :string, limit: 255 }
  end
end
