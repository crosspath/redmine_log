module LogPlugin
  module UserPatch
    def self.included(base)
      base.class_eval do
        has_many :logs
        
        def self.group_by_job
          csv_options = {col_sep: ';', quote_char: '`'}
          user_ids = pluck(:id).uniq
          csv = CSV.read(Rails.root.join('db', 'user_jobs.csv').to_s, csv_options).to_a
          csv.select! { |row| row[0].to_i.in?(user_ids) }
          people_by_job = csv.group_by { |row| row[1] }
          people_by_job.map { |key, values| [key, values.map { |row| row[0].to_i }] }.to_h
        end
      end
    end
  end
end

ActionDispatch::Callbacks.to_prepare do
  User.send(:include, LogPlugin::UserPatch) unless User.included_modules.include?(LogPlugin::UserPatch)
end
