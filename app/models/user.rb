class User < ApplicationRecord
  validates :email, uniqueness: { message: ' address is already in use' }
  validates :role, inclusion: ['user', 'admin', 'superadmin', 'requested_for_admin']

  before_create :generate_api_key
  has_secure_password

  private

  def generate_api_key
    self.api_key = SecureRandom.hex(16)
  end
end
