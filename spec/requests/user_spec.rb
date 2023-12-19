require 'rails_helper'

RSpec.describe "Users", type: :request do
  describe 'POST #sign_up' do
    it 'creates a new user and returns an API key' do
      post '/sign-up', params: { name: 'TestUser', email: 'test@example.com', password: 'password' }
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)).to have_key('api_key')
    end
  end

  describe 'GET #api_key' do
    let(:user) { FactoryBot.create(:user, email: 'api@example.com', password: 'password') }

    context 'with a valid user' do
      before { allow(controller).to receive(:authenticate_user).and_return(user) }

      it 'returns the API key' do
        get '/api-key', params: { email: 'api@example.com', password: 'password' }
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to have_key('api_key')
      end
    end

    context 'with an incorrect password' do
      before { allow(controller).to receive(:authenticate_user).and_return(user) }

      it 'returns unauthorized' do
        get '/api-key', params: { email: 'api@example.com', password: 'pasword' }
        expect(response).to have_http_status(401)

        expect(response.body).to include('Incorrect password.')
      end
    end
  end

  describe 'POST #request_for_admin_access' do
    let(:valid_user) { FactoryBot.create(:user, email: 'test@example.com', password: 'password') }
    context 'when user requests admin access' do
      before do
        allow(controller).to receive(:authenticate_user).and_return(valid_user)
      end

      it 'returns a success message for a user requesting admin access' do
        patch '/request-admin-access', params: { email: 'test@example.com', password: 'password' }

        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to include('message' => 'Your request is considered, superadmin will authorize you ')
      end

      it 'returns an error for a user who has already requested_for_admin' do
        valid_user.update!(role: 'requested_for_admin')

        patch '/request-admin-access', params: { email: 'test@example.com', password: 'password' }

        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to include('message' => "Already requested, you can further contact superadmin with your  user id = #{valid_user.id} ")
      end

      it 'returns an error for a user who is already an admin' do
        valid_user.update!(role: 'admin')

        patch '/request-admin-access', params: { email: 'test@example.com', password: 'password' }

        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to include('message' => 'Already given admin access.')
      end
    end
  end

  describe 'GET #admin_requests' do
    let(:valid_superadmin) { FactoryBot.create(:user, email: 'superadmin@example.com', password: 'password', role: 'superadmin') }
    let(:valid_user) { FactoryBot.create(:user, email: 'test@example.com', password: 'password', role: 'requested_for_admin') }
    context 'when user is a superadmin' do
      before do
        allow(controller).to receive(:authenticate_superadmin).and_return(valid_superadmin)
      end

      it 'returns a list of users with role requested_for_admin' do
        requested_users = FactoryBot.create_list(:user, 3, role: 'requested_for_admin')

        get '/admin-requests', params: { email: 'superadmin@example.com', password: 'password' }

        expect(response).to have_http_status(200)
      end

      it 'returns an empty list if no users have requested_for_admin role' do
        get '/admin-requests', params: { email: 'superadmin@example.com', password: 'password' }

        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to be_empty
      end
    end

    context 'when user is not a superadmin' do
      before do
        allow(controller).to receive(:authenticate_superadmin).and_return(valid_user)
      end

      it 'returns an unauthorized status' do
        get '/admin-requests', params: { email: 'test@example.com', password: 'password' }

        expect(response).to have_http_status(401)
        expect(JSON.parse(response.body)).to include('error' => 'Only superadmin has access to this resource.')
      end
    end
  end

  describe 'PATCH #admin_request_action' do
    let(:superadmin_user) { FactoryBot.create(:user, email: 'superadmin@gmail.com', role: 'superadmin') }
    let(:requested_users) { FactoryBot.create_list(:user, 3, role: 'requested_for_admin') }

    before do
      allow(controller).to receive(:authenticate_superadmin).and_return(true)
      allow(controller).to receive(:authenticate_user).and_return(superadmin_user)
    end

    context 'with valid superadmin user' do
      it 'updates the role to admin for requested users' do
        user_ids = requested_users.map(&:id).join(',')
        
        patch '/request-action', params: { email: 'superadmin@gmail.com', password: 'password', user_ids: user_ids }
        
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to include('message' => "Given admin access to users with id #{user_ids}")
      end

      it 'renders a message for users who are already admin' do
        admin_user = FactoryBot.create(:user, role: 'admin')
        user_ids = "#{admin_user.id}"

        patch '/request-action', params: { email: 'superadmin@gmail.com', password: 'password',user_ids: user_ids }

        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to include('message' => "Users with id #{admin_user.id} had not requested for admin access or are already admin.")
      end

      it 'renders a message for users who have not requested admin access' do
        user_ids = FactoryBot.create_list(:user, 3, role: 'user').map(&:id).join(',')

        patch '/request-action', params: { email: 'superadmin@gmail.com', password: 'password', user_ids: user_ids }

        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)).to include('message' => "Users with id #{user_ids} had not requested for admin access or are already admin.")
      end
    end

    context 'with invalid superadmin user' do
      before do
        allow(controller).to receive(:user).and_return(false)
      end

      it 'renders an unauthorized message' do
        superadmin_user.update!(role: 'admin')
        patch '/request-action', params: { email: 'superadmin@gmail.com', password: 'password', user_ids: requested_users.map(&:id).join(',') }

        expect(response).to have_http_status(401)
        expect(JSON.parse(response.body)).to include('error' => 'Only superadmin has access to this resource.')
      end
    end
  end
end
