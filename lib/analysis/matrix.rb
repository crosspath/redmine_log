module LogPlugin
  module Analysis
    class Matrix
      attr_accessor :matrix, :skip_indices
      
      # new([[elem, ...], ...]) { |row_of_elems, matrix_row| matrix_row += row_of_elems }
      def initialize(data)
        @matrix = []
        @skip_indices = []
        data.each do |row|
          matrix_row = []
          yield row, matrix_row
          @matrix << matrix_row
        end
      end
      
      def index(elem)
        if @skip_indices.blank?
          matrix.index(elem)
        else
          matrix.each_index do |index|
            next if index.in?(@skip_indices)
            return index if matrix[index] == elem
          end
          nil
        end
      end # def
    end # class
  end
end
