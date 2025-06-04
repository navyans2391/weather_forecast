require 'rails_helper'

# This spec tests the WeatherService class which is responsible for:
# - Converting addresses to coordinates using Geocoder
# - Fetching current weather data from OpenWeatherMap API
# - Fetching forecast data for accurate temperature ranges
# - Processing and formatting weather information
# - Handling various error scenarios and edge cases
RSpec.describe WeatherService do
  let(:api_key) { ENV['OPENWEATHERMAP_API_KEY'] }
  # Initialize a new instance of WeatherService for each test
  let(:service) { described_class.new(api_key) }

  describe '#get_forecast' do
    # Test suite for successful weather data retrieval
    context 'with valid address' do
      before do
        # Mock Geocoder to return New York coordinates
        # This prevents actual geocoding API calls during testing
        allow(Geocoder).to receive(:coordinates).with('New York').and_return([40.7128, -74.0060])
        
        # Mock the current weather API endpoint
        # Simulates a successful response with realistic weather data
        # Including temperature, humidity, wind, and location information
        stub_request(:get, "http://api.openweathermap.org/data/2.5/weather")
          .with(
            query: {
              lat: 40.7128,
              lon: -74.0060,
              appid: api_key,
              units: 'metric'  # Ensures temperature is in Celsius
            }
          )
          .to_return(
            status: 200,
            body: {
              main: {
                temp: 20,        # Current temperature
                feels_like: 22,  # Perceived temperature
                temp_min: 18,    # Minimum temperature
                temp_max: 23,    # Maximum temperature
                humidity: 65,    # Humidity percentage
                pressure: 1015   # Atmospheric pressure
              },
              weather: [{ description: 'clear sky' }],  # Weather condition
              wind: { speed: 5.5 },                     # Wind speed in m/s
              name: 'New York',                         # City name
              sys: {
                country: 'US',                          # Country code
                sunrise: Time.now.to_i,                 # Sunrise time
                sunset: (Time.now + 12.hours).to_i      # Sunset time
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Mock the forecast API endpoint
        # Provides temperature data points for calculating daily min/max
        stub_request(:get, "http://api.openweathermap.org/data/2.5/forecast")
          .with(
            query: {
              lat: 40.7128,
              lon: -74.0060,
              appid: api_key,
              units: 'metric'
            }
          )
          .to_return(
            status: 200,
            body: {
              list: [
                { dt: Time.now.to_i, main: { temp: 19 } },
                { dt: Time.now.to_i, main: { temp: 24 } }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      # Verify that the service correctly processes and returns weather data
      it 'returns weather data' do
        result = service.get_forecast('New York')
        
        expect(result).to include(
          temperature: 20.0,
          feels_like: 22.0,
          description: 'clear sky',
          city: 'New York',
          country: 'US'
        )
        
        expect(result[:temp_min]).to be_between(18, 19).inclusive
        expect(result[:temp_max]).to be_between(23, 24).inclusive
        expect(result[:humidity]).to eq(65)
        expect(result[:wind_speed]).to eq(5.5)
      end
    end

    context 'with invalid address' do
      before do
        allow(Geocoder).to receive(:coordinates).with('Invalid Location').and_return(nil)
      end

      it 'returns error message' do
        result = service.get_forecast('Invalid Location')
        expect(result).to include(
          error: "Could not find location: Invalid Location. Please check the address and try again."
        )
      end
    end

    context 'when API returns an error' do
      before do
        # Mock successful geocoding but failed API authentication
        allow(Geocoder).to receive(:coordinates).with('New York').and_return([40.7128, -74.0060])
        
        # Simulate 401 Unauthorized response for both API endpoints
        stub_request(:get, "http://api.openweathermap.org/data/2.5/weather")
          .with(
            query: {
              lat: 40.7128,
              lon: -74.0060,
              appid: api_key,
              units: 'metric'
            }
          )
          .to_return(status: 401)  # Unauthorized status code
        
        stub_request(:get, "http://api.openweathermap.org/data/2.5/forecast")
          .with(
            query: {
              lat: 40.7128,
              lon: -74.0060,
              appid: api_key,
              units: 'metric'
            }
          )
          .to_return(status: 401)  # Unauthorized status code
      end

      # Verify proper handling of API authentication errors
      it 'returns API error message' do
        result = service.get_forecast('New York')
        expect(result).to include(
          error: "Invalid API key. Please check your configuration."
        )
      end
    end

    context 'when location not found in API' do
      before do
        allow(Geocoder).to receive(:coordinates).with('New York').and_return([40.7128, -74.0060])
        
        stub_request(:get, "http://api.openweathermap.org/data/2.5/weather")
          .with(
            query: {
              lat: 40.7128,
              lon: -74.0060,
              appid: api_key,
              units: 'metric'
            }
          )
          .to_return(status: 404)
        
        stub_request(:get, "http://api.openweathermap.org/data/2.5/forecast")
          .with(
            query: {
              lat: 40.7128,
              lon: -74.0060,
              appid: api_key,
              units: 'metric'
            }
          )
          .to_return(status: 404)
      end

      it 'returns location not found error' do
        result = service.get_forecast('New York')
        expect(result).to include(
          error: "Location not found. Please try a different location."
        )
      end
    end
  end
end 