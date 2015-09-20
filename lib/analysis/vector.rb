module LogPlugin
  module Analysis
    module Vector
      module_function
      
      def sum_vectors(vectors)
        vector = Array.new(vectors[0].size, 0) # vectors[0].size элементов со значением 0
        vectors.each { |arg| arg.each_with_index { |value, index| vector[index] += value } }
        vector
      end
      
      def subtract_vectors(vector1, vector2, threshold = 0)
        vector = Array.new(vector1.size, 0) # vector1.size элементов со значением 0
        vector1.each_with_index { |value, index| vector[index] = value - vector2[index] }
        if threshold > 0
          # обнуляем значения, которые кажутся незначительными относительно максимального числа
          max = vector.map(&:abs).max
          limit = threshold * max
          vector.map! { |value| value.abs < limit ? 0 : value }
        end
        vector
      end
      
      # расчёт разницы между соседями по различиям их значений
      def distance(node1, node2)
        node1.size.times.map { |t| (node1[t] - node2[t]).abs }.sum
      end
    end
  end
end
