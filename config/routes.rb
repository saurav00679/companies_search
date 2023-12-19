Rails.application.routes.draw do
  post '/sign-up', to: 'user#sign_up'
  get '/api-key', to: 'user#api_key'
  patch '/request-admin-access', to: 'user#request_for_admin_access'
  get '/admin-requests', to: 'user#admin_requests'
  patch '/request-action', to: 'user#admin_request_action'

  get '/company', to: 'company#show'
  get '/companies', to: 'company#list'
  get '/search-company', to: 'company#search'
  post '/create-company', to: 'company#create'
end
