Dir[File.dirname(__FILE__) + '/analysis/*.rb'].each { |file| require file }

module LogPlugin
  module Analysis
    extend ActiveSupport::Concern
    #extend ClassMethods
    
    # Examples:
    # Log.interval(Date.yesterday).views
    # Log.interval(Date.parse('2015-05-11'), Date.parse('2015-05-17')).visits

    module ClassMethods
      # Сессии
      def each_session(fields)
        fields = fields.map(&:to_s)
        select_logs = reorder(:created_at)
        ids_logs = where('id = first_id')
        ids_logs.select_values = [:id]
        
        ids_logs.find_each do |obj|
          id = obj.id
          yield id, select_logs.where(first_id: id).map { |log| log.attributes.slice(*fields).values.compact.join(' ') }
        end
      end
      
      def sessions(fields)
        transactions = {}
        each_session(fields) { |id, path| transactions[id] = path }
        transactions
      end

      def write_sessions_to_csv(fields, filename, mode = 'w', csv_options = {})
        csv_options.symbolize_keys!
        csv_options[:col_sep] ||= ';'
        CSV.open(filename, mode, csv_options) do |csv|
          each_session(fields) { |id, path| csv << path }
        end
      end
      
      # Поиск ассоциаций с помощью алгоритма Apriori
      # Example:
      # alg = Log.apriori(Log.sessions([:http_method, :query]).map(&:last))
      # alg.association_rules
      def apriori(transactions, min_support = 0.01, min_confidence = 0.6)
        algorithm = Apriori::Algorithm.new(min_support, min_confidence)
        algorithm.analyze(transactions)
      end
      
      # кластеризация
      
      def controllers_linkage(clusters_count = 4)
        rows_grouped_by_user = select(:controller, :user_id).where('controller is not null').group_by(&:user_id)
        # [[controller, ...], ...]
        data = rows_grouped_by_user.values.map { |x| x.map(&:controller) }
        # теперь сформируем матрицу сходства (близости)
        # [[количество запросов пользователя j=0 по контроллеру i=0; i=1; ... i=N], ...]
        controllers = self.controllers
        matrix = LogPlugin::Analysis::Matrix.new(data) do |data_row, matrix_row|
          controllers.each { |c| matrix_row << data_row.select { |elem| elem == c }.count }
        end
        # найдём кластеры и посчитаем расстояния между ними
        clusters = Cluster.clusters(matrix, controllers, clusters_count)
        differences = Cluster.clusters_differences(clusters)
        # по каждому кластеру посчитаем ошибку
        errors = Cluster.clusters_errors(clusters)
        # в каждом кластере определяем, какие контроллеры используются (т.е. значения > 0)
        using_controllers = Cluster.extract_characteristics(clusters, controllers)
        
        {clusters: clusters, controllers: using_controllers, differences: differences, errors: errors}
      end
      
      def user_segments(clusters_count = 4, options = {})
        options.symbolize_keys!
        options[:threshold] = options[:threshold] || 0.1
        # [[controller, ...], ...]
        rows = select(:controller, :action, :user_id).where('controller is not null and action is not null')
        data = rows.group_by(&:user_id).values.map { |x| x.map(&:controller_and_action) }
        # теперь сформируем матрицу сходства (близости)
        # [[количество запросов пользователя j=0 по функции i=0; i=1; ... i=N], ...]
        functions = rows.map(&:controller_and_action).uniq
        matrix = LogPlugin::Analysis::Matrix.new(data) do |data_row, matrix_row|
          functions.each { |c| matrix_row << data_row.select { |elem| elem == c }.count }
        end
        # найдём кластеры и посчитаем расстояния между ними
        clusters = Cluster.clusters(matrix, functions, clusters_count)
        differences = Cluster.clusters_differences(clusters)
        # по каждому кластеру посчитаем ошибку
        errors = Cluster.clusters_errors(clusters)
        # надо определить, что является общим для пользователей в каждом кластере
        characteristics = Cluster.common_characteristics(clusters, functions, options)
        
        {clusters: clusters, characteristics: characteristics, differences: differences, errors: errors}
      end
    end
  end
end

ActionDispatch::Callbacks.to_prepare do
  Log.send(:include, LogPlugin::Analysis) unless Log.included_modules.include?(LogPlugin::Analysis)
end
