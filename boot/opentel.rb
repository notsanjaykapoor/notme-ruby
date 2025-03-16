module Boot
  class OpenTel

    def initialize
      @struct = Struct.new(:code, :tracer, :errors)
    end

    def call
      struct = @struct.new(0, nil, [])

      if !ENV.fetch("OTEL_EXPORTER_OTLP_ENDPOINT", nil)
        struct.code = 404

        Console.logger.info(self, "opentelemetry not configured")

        return struct
      end

      OpenTelemetry::SDK.configure do |c|
        c.use "OpenTelemetry::Instrumentation::GraphQL"
        c.use "OpenTelemetry::Instrumentation::Net::HTTP"
        c.use "OpenTelemetry::Instrumentation::PG"
        c.use "OpenTelemetry::Instrumentation::Rack"
        # c.use_all() # enables all trace instrumentation, can't be used with c.use statement
      end
    
      struct.tracer = OpenTelemetry.tracer_provider.tracer("app")

      Console.logger.info(self, "opentelemetry initialized")

      struct
    end

  end
end
