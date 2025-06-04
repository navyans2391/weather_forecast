require 'rails_helper'

RSpec.describe WeatherController, type: :controller do
  describe 'GET #index' do
    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end
  end

  describe 'POST #forecast' do
    let(:weather_service) { instance_double(WeatherService) }
    let(:api_key) { ENV['OPENWEATHERMAP_API_KEY'] }

    before do
      allow(WeatherService).to receive(:new).with(api_key).and_return(weather_service)
    end

    context 'with valid address' do
      let(:weather_data) do
        {
          temperature: 20.0,
          feels_like: 22.0,
          temp_min: 18.0,
          temp_max: 23.0,
          humidity: 65,
          wind_speed: 5.5,
          description: 'clear sky',
          city: 'New York',
          country: 'US',
          sunrise: '06:00',
          sunset: '18:00'
        }
      end

      before do
        allow(weather_service).to receive(:get_forecast).with('New York').and_return(weather_data)
      end

      it 'renders the forecast template' do
        post :forecast, params: { address: 'New York' }
        expect(response).to render_template(:forecast)
      end

      it 'assigns weather data' do
        post :forecast, params: { address: 'New York' }
        expect(assigns(:weather_data)).to eq(weather_data)
      end

      it 'sets cache flag' do
        post :forecast, params: { address: 'New York' }
        expect(assigns(:from_cache)).to be_in([true, false])
      end
    end

    context 'with empty address' do
      it 'redirects to index with alert' do
        post :forecast, params: { address: '' }
        expect(response).to redirect_to(weather_index_path)
        expect(flash[:alert]).to eq('Please enter an address.')
      end
    end

    context 'with invalid address' do
      before do
        allow(weather_service).to receive(:get_forecast)
          .with('Invalid Location')
          .and_return({ error: 'Could not find location: Invalid Location. Please check the address and try again.' })
      end

      it 'redirects to index with error message' do
        post :forecast, params: { address: 'Invalid Location' }
        expect(response).to redirect_to(weather_index_path)
        expect(flash[:alert]).to eq('Could not find location: Invalid Location. Please check the address and try again.')
      end
    end

    context 'when API returns an error' do
      before do
        allow(weather_service).to receive(:get_forecast)
          .with('New York')
          .and_return({ error: 'Error fetching weather data. Please try again later.' })
      end

      it 'redirects to index with error message' do
        post :forecast, params: { address: 'New York' }
        expect(response).to redirect_to(weather_index_path)
        expect(flash[:alert]).to eq('Error fetching weather data. Please try again later.')
      end
    end
  end
end 