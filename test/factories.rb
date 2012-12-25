FactoryGirl.define do
  factory :user do
    sequence(:name) {|n| "User #{n}"}
    email { name.downcase.gsub(/\s/,'') + "@example.com" }
    location "Anytown, USA"
    password "password"
    password_confirmation { password }

    factory :student do
      sequence(:name) {|n| "Student #{n}"}
      studying "philosophy"
      school "U. of California"
      sequence(:address) {|n| "#{n} Main St\nAnytown, USA"}
    end

    factory :donor do
      sequence(:name) {|n| "Donor #{n}"}
    end

    trait :no_address do
      address ""
    end
  end

  factory :book do
    sequence(:title) {|n| "Book #{n}"}
  end

  factory :request do
    association :user, factory: :student
    book
    reason "I've heard so much about this"
    pledge "1"

    factory :request_no_address do
      association :user, factory: [:student, :no_address]
    end
  end

  factory :donation do
    request
    association :user, factory: :donor

    initialize_with { request.grant! user }

    factory :donation_for_request_no_address do
      association :request, factory: :request_no_address
    end
  end
end
