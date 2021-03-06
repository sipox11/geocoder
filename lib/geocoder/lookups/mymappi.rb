require 'geocoder/lookups/nominatim'
require "geocoder/results/mymappi"

module Geocoder::Lookup
  class Mymappi < Nominatim
    def name
      "mymappi"
    end

    def required_api_key_parts
      ["api_key"]
    end

    private # ----------------------------------------------------------------

    def base_query_url(query)
      method = query.reverse_geocode? ? "geocoding/reverse" : "geocoding/direct"
      "#{protocol}://#{configured_host}/v1/#{method}?"
    end

    def query_url_params(query)
      {
          apikey: configuration.api_key
      }.merge(super)
    end

    def configured_host
      configuration[:host] || "api.mymappi.com"
    end

    def results(query)
      return [] unless doc = fetch_data(query)

      if !doc.is_a?(Array)
        case doc['error']
        when "Invalid key"
          raise_error(Geocoder::InvalidApiKey, doc['error'])
        when "Key not active - Please write to admin@mymappi.com"
          raise_error(Geocoder::RequestDenied, doc['error'])
        when "Rate Limited"
          raise_error(Geocoder::OverQueryLimitError, doc['error'])
        when "Unknown error - Please try again after some time"
          raise_error(Geocoder::InvalidRequest, doc['error'])
        end
      end

      doc.is_a?(Array) ? doc : [doc]
    end
  end
end
