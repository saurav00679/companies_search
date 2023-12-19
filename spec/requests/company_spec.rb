require 'rails_helper'

RSpec.describe "Companies", type: :request do
  let(:valid_api_key) { 'valid_api_key' }
  let(:user) { FactoryBot.create(:user, email: 'test1@gmail.com') }

  before do
    allow(UserHelper).to receive(:authenticate_user).with(valid_api_key).and_return(user)
  end

  describe 'GET /company' do
    context 'with a valid user' do

      it 'returns a successful response with valid name' do
        company = FactoryBot.create(:company, name: 'ExampleCompany')

        get '/company', params: { name: 'ExampleCompany', api_key: valid_api_key }

        expect(response).to have_http_status(200)
        expect(response.body).to include(company.to_json)
      end

      it 'returns an error with missing name' do
        get '/company', params: { api_key: valid_api_key }

        expect(response).to have_http_status(400)
        expect(response.body).to include('Please provide name to get company')
      end

      it 'returns an error when the company is not found' do
        get '/company', params: { name: 'NonExistentCompany', api_key: valid_api_key }

        expect(response).to have_http_status(404)
        expect(response.body).to include('No company with name NonExistentCompany')
      end
    end

    context 'with an invalid user' do
      let(:user) { nil }

      it 'returns unauthorized' do
        get '/company', params: { name: 'ExampleCompany', api_key: valid_api_key }

        expect(response).to have_http_status(401)
        expect(response.body).to include('User not authenticated, check the API key.')
      end
    end
  end

  describe 'GET /companies' do
    it 'returns a list of companies' do
      companies = FactoryBot.create_list(:company, 3)

      get '/companies', params: { api_key: 'valid_api_key' }

      expect(response).to have_http_status(200)

      expected_data = companies.map { |company| company.slice(:id, :name, :location) }
      expect(JSON.parse(response.body)).to match_array(expected_data)
    end
  end

  describe 'GET /search-company' do
    it 'returns companies matching the search key' do
      company = FactoryBot.create(:company, name: 'ExampleCompany')

      get '/search-company', params: { 'search-key' => 'Example', api_key: 'valid_api_key' }

      expect(response).to have_http_status(200)
      expect(response.body).to include(company.to_json)
    end

    it 'returns an error with missing search key' do
      get '/search-company', params: { api_key: 'valid_api_key' }

      expect(response).to have_http_status(400)
      expect(response.body).to include('Please provide search-key to search companies')
    end

    it 'returns an error when no companies match the search key' do
      get '/search-company', params: { 'search-key' => 'NonExistentCompany', api_key: 'valid_api_key' }

      expect(response).to have_http_status(404)
      expect(response.body).to include('No company with keyword NonExistentCompany')
    end
  end

  describe 'POST /create-company' do
    context 'with admin or superadmin user' do
      it 'creates a new company' do
        user = FactoryBot.create(:user, email:'admin@gmail.com', role: 'admin')
        allow(UserHelper).to receive(:authenticate_user).with(user.api_key).and_return(user)

        post '/create-company', params: { name: 'NewCompany', api_key: user.api_key }

        expect(response).to have_http_status(200)
        expect(response.body).to include('NewCompany')
      end

      it 'renders an error with missing parameters' do
        user = FactoryBot.create(:user,email:'superadmin@gmail.com', role: 'user')
        allow(UserHelper).to receive(:authenticate_user).with(user.api_key).and_return(user)

        post '/create-company', params: { name: nil, api_key: user.api_key }

        expect(response).to have_http_status(401)
        expect(response.body).to include('error')
      end
    end
  end
end
