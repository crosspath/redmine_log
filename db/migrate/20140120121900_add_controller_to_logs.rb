class AddControllerToLogs < ActiveRecord::Migration
  def change
    change_table :logs do |t|
      t.string :controller
    end
  end
end
# 1 минута, 4 миллиона записей
