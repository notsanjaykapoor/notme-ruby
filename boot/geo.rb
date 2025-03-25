module Boot
  class Geo

    def initialize
      @struct = Struct.new(:code, :name, :errors)
    end

    def call
      struct = @struct.new(0, "", [])
      
      if key = ENV.fetch("GEO_GEOAPIFY_KEY", nil)
        Geocoder.configure(
          lookup: :geoapify,
          api_key: key,
        )

        struct.name = "geoapify"
      elsif key = ENV.fetch("GEO_OPENCAGEDATA_KEY", nil)
        Geocoder.configure(
          lookup: :opencagedata,
          api_key: key,
        )

        struct.name = "opencagedata"
      else
        # no api key required
        Geocoder.configure(
          lookup: :nominatim,
        )

        struct.name = "nominatim"
      end

      struct
    end

  end
end
