FactoryGirl.define do
  factory :location do
    name "Anytown, USA"
    geocoder_results [{'address_components' => [{'long_name' => 'United States', 'types' => ['country']}]}]

    factory :foreign_location do
      name "Somewhere, UK"
      geocoder_results [{'address_components' => [{'long_name' => 'United Kingdom', 'types' => ['country']}]}]
    end
  end

  factory :user do
    sequence(:name) {|n| "User #{n}"}
    email { name.downcase.gsub(/\s/,'') + "@example.com" }
    location
    password "password"
    password_confirmation { password }

    trait(:no_address) {address ""}
    trait(:foreign) {association :location, factory: :foreign_location}

    factory :student do
      sequence(:name) {|n| "Student #{n}"}
      studying "philosophy"
      school "U. of California"
      sequence(:address) {|n| "#{n} Main St\nAnytown, USA"}
    end

    factory :donor do
      sequence(:name) {|n| "Donor #{n}"}
      after(:create) {|user| create :pledge, user: user}
    end

    factory :volunteer do
      sequence(:name) {|n| "Volunteer #{n}"}
      roles ['volunteer']
    end
  end

  factory :book do
    sequence(:title) {|n| "Book #{n}"}
    sequence(:asin) {|n| "B%09d" % n}
    price 10

    trait(:no_price) {price nil}
    trait(:no_asin) {asin nil}
  end

  factory :request do
    association :user, factory: :student
    book
    reason "I've heard so much about this"
    pledge "1"

    trait(:canceled) {canceled true}

    trait :renewable do
      created_at {5.weeks.ago}
      open_at {5.weeks.ago}
    end

    trait :autocancelable do
      created_at {9.weeks.ago}
      open_at {9.weeks.ago}
    end

    factory :request_no_address do
      association :user, factory: [:student, :no_address]
    end

    factory :request_foreign_student do
      association :user, factory: [:student, :foreign]
    end

    factory :request_not_amazon do
      association :book, factory: [:book, :no_asin, :no_price]
    end
  end

  factory :pledge do
    association :user, factory: :donor
    quantity 5

    trait(:ended) {ended true}
    trait(:canceled) {canceled true}
    trait(:endable) {created_at {5.weeks.ago}}
  end

  factory :donation do
    association :user, factory: :donor
    request
    status 'not_sent'

    initialize_with { request.grant! user }

    factory :donation_for_request_no_address do
      association :request, factory: :request_no_address
    end

    factory :donation_for_request_foreign_student do
      association :request, factory: :request_foreign_student
    end

    factory :donation_for_request_not_amazon do
      association :request, factory: :request_not_amazon
    end

    trait(:paid) {paid true}
    trait(:sent) {status 'sent'}
    trait(:flagged) {flagged true}
  end

  factory :fulfillment do
    association :user, factory: :volunteer
    association :donation, :paid, factory: :donation
  end

  factory :review do
    association :user, factory: :student
    book
    donation nil
    text "I really enjoyed it!"
    recommend true
  end
end
