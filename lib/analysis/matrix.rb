module LogPlugin
  module Analysis
    class Matrix
      attr_accessor :matrix
      
      # new([[elem, ...], ...]) { |row_of_elems, matrix_row| matrix_row += row_of_elems }
      def initialize(data)
        @matrix = []
        data.each do |row|
          matrix_row = []
          yield row, matrix_row
          @matrix << matrix_row
        end
      end
    end
  end
end
