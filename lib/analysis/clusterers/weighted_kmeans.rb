module LogPlugin
  module Analysis
    module Clusterers
      class WeightedKMeans < Ai4r::Clusterers::KMeans
        # добавлено определение веса
        def weighted_distance(a, b, weight = 1)
          distance(a, b).to_f / (1 + weight) * weight
        end
        
        def eval(data_item)
          distances = @centroids.map.with_index {|centroid, index| weighted_distance(data_item, centroid, @clusters[index].data_items.size) }
          get_min_index(distances)
        end
        
         def sort_data_indices_by_dist_to_centroid 
           sorted_data_indices = []
           h = {}
           @clusters.each_with_index do |cluster, c|
             centroid = @centroids[c]
             cluster.data_items.each_with_index do |data_item, i|
               dist_to_centroid = weighted_distance(data_item, centroid, cluster.data_items.size)
               data_index = @cluster_indices[c][i]
               h[data_index] = dist_to_centroid
             end  
           end
           # sort hash of {index => dist to centroid} by dist to centroid (ascending) and then return an array of only the indices
           sorted_data_indices = h.sort_by{|k,v| v}.collect{|a,b| a}
         end
      end
    end
  end
end
