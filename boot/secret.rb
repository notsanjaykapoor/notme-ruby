# frozen_string_literal: true

module Boot
  class Secret

    def initialize
      @struct = Struct.new(:code, :errors)
    end

    def call
      struct = @struct.new(0, [])

      dot_files = _dot_files

      dot_files.each do |file|
        Dotenv.load(file)
      end

      Console.logger.info(self, "env files #{dot_files}")

      struct
    end

    protected

    def _dot_files
      dot_file = ["./.env", ENV["RACK_ENV"]].compact.join(".")

      [dot_file].select{ |file| File.exist?(file) }
    end

  end
end
