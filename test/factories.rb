FactoryGirl.define do
  factory :user do
    name "John Galt"
    email { "#{name.downcase.gsub(' ','.')}@example.com" }
    location "Atlantis, CO"
    password "password"
    password_confirmation { password }

    factory :student do
      name "Hank Rearden"
      location "Philadelphia, PA"
      studying "manufacturing"
      school "University of Pittsburgh"
      address "987 Steel Way\nPhiladelphia, PA 12345"
    end

    factory :donor do
      name "Hugh Akston"
      location "Boston, MA"
    end

    trait :no_address do
      address ""
    end
  end

  factory :book do
    title "Atlas Shrugged"
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
