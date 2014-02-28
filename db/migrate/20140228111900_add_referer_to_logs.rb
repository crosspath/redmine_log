class AddRefererToLogs < ActiveRecord::Migration
  def change
    change_table :logs do |t|
      t.string :referer
    end
  end
end
# 1 минута, 4 миллиона записей
