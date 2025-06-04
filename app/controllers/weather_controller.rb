class WeatherController < ApplicationController
  def index
  end

  def forecast
    @address = params[:address]
    
    if @address.present?
      # Check cache first
      cache_key = "weather_#{@address.downcase.gsub(/\s+/, '_')}"
      
      @weather_data = Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
        # Only call the API if data is not in cache
        weather_service = WeatherService.new(ENV['OPENWEATHERMAP_API_KEY'])
        weather_service.get_forecast(@address)
      end
      
      if @weather_data&.key?(:error)
        # If there's an error, remove the failed attempt from cache
        Rails.cache.delete(cache_key)
        redirect_to weather_index_path, alert: @weather_data[:error]
      else
        @from_cache = Rails.cache.exist?(cache_key)
        render :forecast
      end
    else
      redirect_to weather_index_path, alert: "Please enter an address."
    end
  end
end
