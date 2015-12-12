Dir[File.dirname(__FILE__) + '/clusterers/*.rb'].each { |file| require file }

module LogPlugin
  module Analysis
    module Clusterers
    end
  end
end
