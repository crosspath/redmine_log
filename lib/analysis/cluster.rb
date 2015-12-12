module LogPlugin
  module Analysis
    module Cluster
      module_function
      
      # clusterer_options: ClustererWrapper
      def clusters(clusterer_options)
        data = clusterer_options.data.matrix
        # data_labels не нужен здесь, но без него алгоритм не работает
        data_set = Ai4r::Data::DataSet.new(data_items: data, data_labels: data.first)
        
        clusterer = case clusterer_options.clusters_distance_method
                      when :weighted_centroid
                        LogPlugin::Analysis::Clusterers::WeightedKMeans
                      when :weighted_average
                        LogPlugin::Analysis::Clusterers::WeightedAverageLinkage
                      else
                        raise ArgumentError, 'Other clusterers are not supported.'
                    end
        
        algorithm = clusterer.new
        algorithm.distance_function = clusterer_options.vectors_distance_method
        algorithm.build(data_set, clusterer_options.clusters_count)
        
        result = algorithm.clusters
        result.map(&:data_items)
      end
      
      # перебор всех пар и выбор наименьшего, наибольшего и среднего расстояний
      def clusters_distance(cluster1, cluster2)
        distances = []
        cluster1.each do |value1|
          cluster2.each do |value2|
            distances << Vector.distance(value1, value2)
          end
        end
        {min: distances.min, max: distances.max, avg: distances.avg}
      end
      
      def clusters_differences(clusters)
        clusters_size = clusters.size
        # [cluster_index1 [cluster_index2 {min: 0, max: 0, avg: 0}, ...], ...]
        differences = Array.new(clusters_size) { Array.new(clusters_size) { Hash.new } }
        
        clusters.each_with_index do |cluster1, index1|
          offset_index2 = index1+1
          
          clusters[offset_index2 .. -1].each_with_index do |cluster2, i|
            index2 = i + offset_index2
            
            s = clusters_distance(cluster1, cluster2)
            differences[index1][index2] = differences[index2][index1] = s
          end
        end
        differences
      end
      
      def cluster_center(cluster)
        cluster_size = cluster.size
        sum = Vector.sum_vectors(cluster)
        sum.map! { |value| value.to_f / cluster_size }
      end
      
      # среднеквадратическая ошибка
      # center - эталон
      def mean_square_error(center, cluster)
        square_errors_sum = cluster.reduce(0) { |a, elem| a + (Vector.distance(elem, center)) ** 2 }
        Math.sqrt(square_errors_sum.to_f / cluster.size)
      end
      
      def clusters_errors(clusters)
        errors = []
        clusters.each_with_index do |cluster1, index1|
          center = cluster_center(cluster1)
          errors[index1] = mean_square_error(center, cluster1)
        end
        errors
      end
      
      # как элементы labels распределены по кластерам
      def extract_characteristics(clusters, labels)
        result = Hash.new_with_default { Array.new(clusters.size) } # {label: [cluster_index sum, ...]}
        clusters.each_with_index do |cluster, cluster_index|
          labels.each_with_index do |elem, index|
            result[elem][cluster_index] = cluster.sum { |row| row[index] }.to_f
          end
        end
        # нормализация
        result = result.map do |k, usage|
          sum = usage.sum.to_f
          [k, usage.map { |value| value / sum}]
        end.to_h # {label: [0.94, 0.01, ...], ...}
      end
      
      def common_characteristics(clusters, labels, options = {})
        options.symbolize_keys!
        threshold = options[:threshold] || 0.1
        clusters_size = clusters.size
        
        result = Array.new(clusters_size) { Array.new } # [{elem: count, ...}, ...]
        centers = clusters.map { |cluster| cluster_center(cluster) }
        
        clusters.each_index do |index1|
          subt = centers[index1].dup
          Vector.reject_minor_values!(subt, threshold)
          subt.each_with_index do |elem, label_index|
            result[index1] << labels[label_index] if elem > 0
          end
          result[index1].sort!
        end
        result
      end
      
    end
  end
end
