module LogPlugin
  module Analysis
    module Vector
      module_function
      
      def sum_vectors(vectors)
        vector = Array.new(vectors[0].size, 0) # vectors[0].size элементов со значением 0
        vectors.each { |arg| arg.each_with_index { |value, index| vector[index] += value } }
        vector
      end
      
      def subtract_vectors(vector1, vector2)
        vector = Array.new(vector1.size, 0) # vector1.size элементов со значением 0
        vector1.each_with_index { |value, index| vector[index] = value - vector2[index] }
        vector
      end
      
      # расчёт разницы между соседями по различиям их значений
      def distance(node1, node2)
        Math.sqrt(node1.size.times.map { |t| (node1[t] - node2[t]) ** 2 }.sum)
      end
      
      # обнуляем значения, которые кажутся незначительными относительно максимального числа
      def reject_minor_values!(vector, threshold = 0.1)
        return vector if threshold <= 0
        max = vector.map(&:abs).max
        limit = threshold * max
        vector.map! { |value| value.abs < limit ? 0 : value }
      end
    end
  end
end
