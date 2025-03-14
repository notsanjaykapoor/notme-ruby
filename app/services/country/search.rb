module Service
  module Country
    module Search

      def self.map_name_to_code(name:)
        #
        # map country name to 2 letter country code
        #
        geocode_results =  ::Geocoder.search(name)

        address_types = ["country"]
        geocode_results = geocode_results.select{ |o| address_types.include?(o.data.fetch("addresstype", ""))}

        if geocode_results.length == 0
          return ""
        end

        geocode_data = geocode_results[0].data

        return geocode_data.dig("address", "country_code")
      end

    end
  end
end
