Dir[File.dirname(__FILE__) + '/analysis/*.rb'].each { |file| require file }

module LogPlugin
  module Analysis
    class TopLevel
      def initialize(logs)
        @logs = logs
      end
      
      # Сессии
      def each_session(logs = @logs, fields)
        fields = fields.map(&:to_s)
        select_logs = logs.reorder(:created_at)
        ids_logs = logs.where('id = first_id')
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
      # alg = analysis.apriori(analysis.sessions([:http_method, :query]).map(&:last))
      # alg.association_rules
      def apriori(transactions, min_support = 0.01, min_confidence = 0.6)
        algorithm = Apriori::Algorithm.new(min_support, min_confidence)
        algorithm.analyze(transactions)
      end
      
      # кластеризация
      
      def controllers_linkage(clusters_count = 4)
        conditions = 'controller is not null and user_id is not null'
        rows = select(:controller, :user_id).where(conditions).group_large_dataset('user_id')
        # [[controller, ...], ...]
        data = rows.values.map { |group| group.map { |row| row['controller'] }}
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
        
        {clusters: clusters, controllers: using_controllers, differences: differences, errors: errors, labels: controllers}
      end
      
      def user_segments(clusterer_options = nil)
        clusterer_options ||= LogPlugin::Analysis::ClustererWrapper::UserSegments.new
        clusterer_options.clusters_count ||= 4
        clusterer_options.vectors_distance_method ||= -> (a, b) { Ai4r::Data::Proximity.squared_euclidean_distance(a, b) }
        clusterer_options.clusters_distance_method ||= :weighted_centroid
        clusterer_options.set_data(@logs) unless clusterer_options.data
       
        clusterer_options.run
        
        clusterer_options
      end
    end
  end
end

ActionDispatch::Callbacks.to_prepare do
  unless Log.respond_to?(:analysis)
    class Log
      class << self
        def analysis
          LogPlugin::Analysis::TopLevel.new(self.to_ar_relation)
        end
        
        # оптимизация
        def hashes
          connection.select_all(self.to_ar_relation.to_sql)
        end
        
        def group_large_dataset(expr = nil)
          hashes.group_by { |row| row[expr || yield] }
        end
        
        def to_ar_relation
          # use AR_Relation
          self.from(table_name) unless respond_to?(:to_sql)
        end
      end
    end
  end
end
