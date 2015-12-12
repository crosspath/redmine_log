module LogPlugin
  module Analysis
    module Clusterers
      class WeightedAverageLinkage < Ai4r::Clusterers::AverageLinkage
        
        protected
        
        # добавлено определение веса
        
        def distance_between_item_and_cluster(data_item, cluster)
          min_dist = 1.0/0
          cluster.data_items.each do |another_item|
            dist = @distance_function.call(data_item, another_item).to_f / cluster.size
            min_dist = dist if dist < min_dist
          end
          return min_dist
        end
        
        def get_closest_clusters(index_clusters)
          min_distance = 1.0/0
          closest_clusters = [1, 0]
          index_clusters.each_index do |index_a|
            cluster_a_size = index_clusters[index_a].size
            index_a.times do |index_b|
              cluster_b_size = index_clusters[index_b].size
              cluster_distance = read_distance_matrix(index_a, index_b) / (cluster_a_size + cluster_b_size)
              if cluster_distance < min_distance
                closest_clusters = [index_a, index_b]
                min_distance = cluster_distance
              end
            end
          end
          return closest_clusters
        end
      end
    end
  end
end
