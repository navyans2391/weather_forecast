# Weather Forecast Application

A Ruby on Rails application that provides real-time weather information and forecasts based on user-provided locations.

## Features

- Real-time weather data retrieval from OpenWeatherMap API
- Location search using addresses
- Current weather conditions including:
  - Temperature (current, feels like)
  - Temperature range (min/max)
  - Weather description(optional)
  - Humidity(optional)
  - Wind speed(optional)
- 30-minute data caching for improved performance
- Error handling for invalid locations and API issues
- Comprehensive test coverage

## versions used

- Ruby version: 3.2.3
- Rails version: 8.0.2
- mysql database(even though database was not needed)
- OpenWeatherMap API key

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd weather_forecast
```

2. Install dependencies:
```bash
bundle install
```

3. Set up environment variables:
Create a `.env` file in the root directory and add:
OPENWEATHERMAP_API_KEY=your_api_key_here


5. Start the server:
```bash
rails server
```

## Configuration

### API Keys
- Sign up for an API key at [OpenWeatherMap](https://openweathermap.org/api)
- Add the API key to your `.env` file

### Caching
- The application uses Rails caching with a 30-minute expiration

## Testing

Test Suite: Rspec


Test coverage includes:
- WeatherService functionality
- API integration
- Error handling
- Edge cases

## Project Structure

Key files and directories:
- `app/services/weather_service.rb` - Main service for weather data retrieval
- `app/controllers/weather_controller.rb` - Main controller
- `spec/services/weather_service_spec.rb` - Service tests
- `spec/controllers/weather_controller_spec.rb` - Controller tests

## Error Handling

The application handles various error scenarios:
- Invalid locations
- API authentication errors
- Location not found in weather API
- Network connectivity issues

