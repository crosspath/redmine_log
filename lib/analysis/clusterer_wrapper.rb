module LogPlugin
  module Analysis
    class ClustererWrapper
      attr_accessor :clusters_count, :vectors_distance_method, :clusters_distance_method, :data
      attr_reader :clusters, :clusters_distances, :clusters_errors
      
      def initialize(options = {})
        options.symbolize_keys!
        @clusters_count = options.delete(:clusters_count)
        @vectors_distance_method = options.delete(:vectors_distance_method)
        @clusters_distance_method = options.delete(:clusters_distance_method)
        @data = options.delete(:data)
        raise ArgumentError, "Unexpectable parameters: #{options.inspect}" if options.present?
      end
      
      def run
        # найдём кластеры и посчитаем расстояния между ними
        @clusters = Cluster.clusters(self)
        #@clusters_distances = Cluster.clusters_differences(@clusters)
        # по каждому кластеру посчитаем ошибку
        #@clusters_errors = Cluster.clusters_errors(@clusters)
      end
    end
    
    class LogPlugin::Analysis::ClustererWrapper::UserSegments < LogPlugin::Analysis::ClustererWrapper
      attr_reader :functions_by_user, :functions, :users_clusters, :characteristics
      
      def set_data(logs)
        @logs = logs
        set_functions_by_user
        functions_usage = functions_by_user.values
        @functions = functions_usage.flatten.uniq
        @data = calc_matrix(functions_usage)
      end
      
      # [[controller, ...], ...]
      def set_functions_by_user
        rows = []
        selected_logs = @logs
        if @logs.respond_to?(:limit_value) && (@logs.limit_value || @logs.offset_value)
          selected_logs = selected_logs.where('id in (?)', selected_logs.pluck(:id).uniq).limit(nil).offset(nil)
        end
        
        conditions = 'controller is not null and action is not null and user_id is not null'
        selected_logs = selected_logs.select(:controller, :action, :user_id).where(conditions)
        rows = selected_logs.group_large_dataset('user_id')
        @functions_by_user = rows.map do |user_id, log_hashes|
          [user_id.to_i, log_hashes.map { |x| "#{x['controller']}##{x['action']}" }]
        end.to_h
      end
      
      # матрица сходства (близости):
      # [[количество запросов пользователя j=0 по функции i=0; i=1; ... i=N], ...]
      def calc_matrix(functions_usage)
        matrix = LogPlugin::Analysis::Matrix.new(functions_usage) do |data_row, matrix_row|
          @functions.each { |c| matrix_row << data_row.select { |elem| elem == c }.count }
        end
        min = nil; max=nil;
        matrix.matrix.each { |row| m = row.min; min = m if !min || m < min; m = row.max; max = m if !max || m > max };
        zero = (max - min) / 2.0;
        matrix.matrix.map!.with_index { |row, j| row.map! { |e| e -= zero } };
        matrix
      end
      
      def run
        super
        # надо определить, что является общим для пользователей в каждом кластере
        @characteristics = Cluster.common_characteristics(@clusters, @functions)
        
        @users_clusters = Array.new(@clusters_count) { [] }
        fbu = @functions_by_user.to_a
        
        # какие пользователи к каким кластерам относятся
        @clusters.each_with_index do |cluster, cluster_index|
          cluster.each do |elem|
            index = @data.index(elem)
            user_actions = fbu[index]
            @users_clusters[cluster_index] << user_actions[0] # user_id
            @data.skip_indices << index
          end
        end # @clusters
      end # def run
    end # class
  end # module
end # module
