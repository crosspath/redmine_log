class Array
  def avg(&block)
    sum(&block).to_f / size
  end
end
