FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Company #{n}" }
    sequence(:location) { |n| "Location #{n}" }
  end
end