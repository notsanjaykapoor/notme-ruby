# frozen_string_literal: true

module Service
    module Twelve
      class PriceRandom
  
        def initialize(symbols:)
          @symbols = symbols
  
          @struct = Struct.new(:code, :data, :errors)
        end
  
        def call
          struct = @struct.new(0, {}, [])
  
          Console.logger.info(self, "#{Thread.current[:rid]} #{@symbols}")
  
          # generate random data
          struct.data = @symbols.reduce({}) { |h, s| h[s] = {"price" => "#{300 + rand(200)}"}; h }.transform_keys(&:to_s)
    
          struct
        end
  
      end
    end
  end
    