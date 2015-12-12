module LogPlugin
  module Analysis
    module Groups
      module_function
      
      def maximum_deviation(size)
        # ceil: округление вверх.
        size == 1 ? 0 : (size / 4.0).ceil
      end
      
      def similar?(a, b)
        # Размер пересечения (т. е. количество совпадающих элементов).
        intersection_size = (a & b).size
        a_deviation = maximum_deviation(a.size)
        b_deviation = maximum_deviation(b.size)
        a.size - intersection_size <= a_deviation && b.size - intersection_size <= b_deviation
      end
      
      def compare_arrays_of_groups(array_a, array_b)
        # conformity: соответствие [{a: index, b: index}, ...].
        conformity = []
        
        array_a.each_with_index do |group_a, index_a|
          # selected_clusters: индексы групп из B, которым уже нашли
          # соответствующие группы из A.
          selected_clusters = conformity.map { |line| line[:b] }
          
          array_b.each_with_index do |group_b, index_b|
            # Пропустить кластер, если для него уже найдена соответствующая группа.
            next if selected_clusters.include?(index_b)
            
            # Если группы похожи, добавить их индексы в список соответствия.
            if similar?(group_a, group_b)
              conformity << {a: index_a, b: index_b}
              break
            end
          end
        end
        
        conformity
      end
    end
  end
end
