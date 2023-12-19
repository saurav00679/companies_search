FactoryBot.define do
  factory :user do
    name { 'John Doe' }
    sequence(:email) { |n| "john#{n}" + "@example.com" }
    password { 'password' }
    role { 'user' }
  end
end
