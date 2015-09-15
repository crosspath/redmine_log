# require Rails.root.join('plugins', 'redmine_log', 'init.rb').to_s

module LogPlugin
  module Analysis
    extend ActiveSupport::Concern
    
    # Examples:
    # Log.interval(Date.yesterday).views
    # Log.interval(Date.parse('2015-05-11'), Date.parse('2015-05-17')).visits

    class_methods do
      # Сессии
      def each_session
        fields = select_values.map(&:to_s)
        select_logs = reorder(:created_at)
        ids_logs = where('id = first_id')
        ids_logs.select_values = [:id]
        
        ids_logs.find_each do |obj|
          id = obj.id
          yield id, select_logs.where(first_id: id).map { |log| log.attributes.slice(*fields).values.compact.join(' ') }
        end
      end
      
      def apriori(transactions, min_support = 0.01, min_confidence = 0.01)
        algorithm = Apriori::Algorithm.new(min_support, min_confidence)
        algorithm.analyze(transactions)
      end
      
      def sessions
        transactions = {}
        each_session { |id, path| transactions[id] = path }
        transactions
      end
      
      def write_sessions_to_csv(filename, mode = 'w', csv_options = {})
        csv_options.symbolize_keys!
        csv_options[:col_sep] ||= ';'
        CSV.open(filename, mode, csv_options) do |csv|
          each_session { |id, path| csv << path }
        end
    end
  end
end

ActionDispatch::Callbacks.to_prepare do
  Log.send(:include, LogPlugin::Analysis) unless Log.included_modules.include?(LogPlugin::Analysis)
end
