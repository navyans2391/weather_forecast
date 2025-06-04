# Service class responsible for fetching and processing weather data from OpenWeatherMap API
# This class handles:
# - Converting addresses to coordinates using Geocoder
# - Fetching current weather data
# - Fetching forecast data for high/low temperatures
# - Error handling for API responses
# - Data formatting and processing
class WeatherService
  include HTTParty
  base_uri 'http://api.openweathermap.org/data/2.5'

  # Initialize the service with an API key
  # @param api_key [String] OpenWeatherMap API key
  def initialize(api_key)
    @api_key = api_key
  end

  # Fetch weather forecast data for a given address
  # @param address [String] Address to fetch weather for (can be city name, zip code, or full address)
  # @return [Hash] Weather data including temperature, humidity, wind speed, etc.
  #   or error message if the request fails
  def get_forecast(address)
    # Convert address to coordinates using Geocoder
    coordinates = Geocoder.coordinates(address)
    return { error: "Could not find location: #{address}. Please check the address and try again." } unless coordinates

    lat, lon = coordinates
    
    # Get current weather data from OpenWeatherMap API
    current_weather = self.class.get("/weather", query: {
      lat: lat,
      lon: lon,
      appid: @api_key,
      units: 'metric'  # Use Celsius for temperature
    })

    # Get forecast data for calculating daily high/low temperatures
    forecast = self.class.get("/forecast", query: {
      lat: lat,
      lon: lon,
      appid: @api_key,
      units: 'metric'
    })

    # Handle API response errors
    unless current_weather.success? && forecast.success?
      error_message = if current_weather.code == 401 || forecast.code == 401
        "Invalid API key. Please check your configuration."
      elsif current_weather.code == 404 || forecast.code == 404
        "Location not found. Please try a different location."
      else
        "Error fetching weather data. Please try again later."
      end
      return { error: error_message }
    end

    begin
      # Extract today's temperature readings from forecast data
      today = Time.now.to_date
      todays_temps = forecast['list']
        .select { |f| Time.at(f['dt']).to_date == today }  # Filter for today's forecasts
        .map { |f| f['main']['temp'] }                     # Extract temperatures

      # Get current temperature or default to 0 if not available
      current_temp = current_weather.dig('main', 'temp') || 0
      
      # Build response hash with all weather data
      {
        # Current conditions
        temperature: current_temp,
        temp_min: (todays_temps.min || current_weather.dig('main', 'temp_min') || current_temp).to_f,
        temp_max: (todays_temps.max || current_weather.dig('main', 'temp_max') || current_temp).to_f,
        feels_like: (current_weather.dig('main', 'feels_like') || current_temp).to_f,
        humidity: current_weather.dig('main', 'humidity') || 0,
        pressure: current_weather.dig('main', 'pressure') || 0,
        wind_speed: current_weather.dig('wind', 'speed') || 0,
        description: current_weather.dig('weather', 0, 'description') || 'No description available',
        city: current_weather['name'] || address,
        country: current_weather.dig('sys', 'country') || '',
        sunrise: current_weather.dig('sys', 'sunrise') ? Time.at(current_weather['sys']['sunrise']).strftime('%H:%M') : 'N/A',
        sunset: current_weather.dig('sys', 'sunset') ? Time.at(current_weather['sys']['sunset']).strftime('%H:%M') : 'N/A'
      }
    rescue => e
      # Log any errors that occur during data processing
      Rails.logger.error("Error processing weather data: #{e.message}")
      { error: "Error processing weather data. Please try again later." }
    end
  end
end 