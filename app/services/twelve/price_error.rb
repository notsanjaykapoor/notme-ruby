# frozen_string_literal: true

module Service
    module Twelve
      class PriceError
  
        def initialize(symbols:)
          @symbols = symbols
  
          @struct = Struct.new(:code, :data, :errors)
        end
  
        def call
          struct = @struct.new(0, {}, [])
  
          Console.logger.info(self, "#{Thread.current[:rid]} #{@symbols}")
  
          # generate price error
          struct.data = @symbols.reduce({}) { |h, s| h[s] = {"code" => "404"}; h }.transform_keys(&:to_s)
    
          struct
        end
  
      end
    end
  end
    