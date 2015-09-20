class Hash
  def self.new_with_default(*args)
    if args.size > 0
      Hash.new { |h, k| h[k] = args.first }
    elsif block_given?
      Hash.new { |h, k| h[k] = yield }
    else
      Hash.new
    end
  end
end
