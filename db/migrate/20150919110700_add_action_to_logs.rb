class AddActionToLogs < ActiveRecord::Migration
  def change
    change_table :logs do |t|
      t.string :action
    end
    reversible do |dir|
      dir.up do
        puts 'Update columns "controller" and "action"'
        Log.find_each do |log|
          params = log.safe_parse_parameters
          log.update!(controller: params['controller'], action: params['action']) if params && params != 'null'
        end
        Log.where(controller: 'null').update_all(controller: nil)
      end
    end
  end
end
