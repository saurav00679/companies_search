module UserHelper
  def self.authenticate_user(api_key)
    User.where(api_key: api_key).first
  end
end
