class UserController < ApplicationController
  before_action :authenticate_user, only: [:api_key, :request_for_admin_access, :admin_requests, :admin_request_action]
  before_action :authenticate_superadmin, only: [:admin_request_action, :admin_requests]

  def sign_up
    user = User.create!(params.permit(:name, :password, :email))

    render json: {api_key: user.api_key}
  end

  def api_key
    render json: { api_key: @user.api_key }
  end

  def request_for_admin_access
    case @user.role
    when 'requested_for_admin'
      render json: { message: "Already requested, you can further contact superadmin with your  user id = #{@user.id} " }
    when 'admin'
      render json: { message: "Already given admin access." }
    else
      @user.update!(role: 'requested_for_admin')
      render json: { message: "Your request is considered, superadmin will authorize you " }
    end
  end

  def admin_requests
    render json: User.where(role: 'requested_for_admin')
  end

  def admin_request_action
    users = User.where(id: params['user_ids'].to_s.split(','), role: 'requested_for_admin')

    if users.exists?
      ids = users.pluck(:id).join(',')
      users.update_all(role: 'admin')

      render json: {message: "Given admin access to users with id #{ids}"}
    else
      render json: {message: "Users with id #{params['user_ids']} had not requested for admin access or are already admin."}
    end
  end

  private

  def authenticate_user
    @user = User.find_by_email(params['email'])

    return render_error('No user with this email. You need to sign up.') if @user.nil?

    render_error('Incorrect password.', :unauthorized) unless @user.authenticate(params['password'])
  end

  def authenticate_superadmin
    render_error('Only superadmin has access to this resource.', :unauthorized) unless @user.role == 'superadmin'
  end

  def render_error(message, status = :bad_request)
    render json: { error: message }, status: status
  end
end
