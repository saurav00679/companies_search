class CompanyController < ApplicationController
  before_action :authenticate_user

  def show
    return render_error("Please provide name to get company", 400) if params['name'].nil?

    company = Company.find_by_name(params['name'])
    if company.nil?
      render_error("No company with name #{params['name']}", 404)
    else
      render json: company
    end
  end

  def list
    companies = Company.select(:id, :name, :location).all

    render json: companies
  end

  def search
    return render_error("Please provide search-key to search companies", 400) if params['search-key'].nil?

    companies = Company.where("name like '%#{params['search-key']}%'")

    if companies.exists?
      render json: companies
    else
      render_error("No company with keyword #{params['search-key']}", 404)
    end
  end

  def create
    if ['admin', 'superadmin'].include?(@user['role'])

      if params['name'].nil? || params['location'].nil?
        return render_error('Name and location cannot be blank.', :unauthorized)
      end

      company = Company.create!(name: params['name'], location: params['location'])

      render json: company
    else
      render_error('Only admin can add new company, you need superadmin authorization.', :unauthorized)
    end
  end

  private

  def authenticate_user
    if params['api_key'].nil?
      return render_error('Please add the API key. Sign up if you do not have one.', :unauthorized)
    end

    @user = UserHelper.authenticate_user(params['api_key'])

    render_error('User not authenticated, check the API key.', :unauthorized) if @user.nil?
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
