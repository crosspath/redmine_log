class AddRefererControllerToLogs < ActiveRecord::Migration
  def change
    change_table :logs do |t|
      t.string :referer_controller
    end
  end
end
