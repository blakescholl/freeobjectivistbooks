FactoryGirl.define do
  factory :location do
    name "Anytown, USA"
    geocoder_results [{'address_components' => [{'long_name' => 'United States', 'types' => ['country']}]}]
  end

  factory :user do
    sequence(:name) {|n| "User #{n}"}
    email { name.downcase.gsub(/\s/,'') + "@example.com" }
    location
    password "password"
    password_confirmation { password }

    factory :student do
      sequence(:name) {|n| "Student #{n}"}
      studying "philosophy"
      school "U. of California"
      sequence(:address) {|n| "#{n} Main St\nAnytown, USA"}

      trait(:no_address) {address ""}
    end

    factory :donor do
      sequence(:name) {|n| "Donor #{n}"}

      trait(:send_books) {donor_mode "send_books"}
      trait(:send_money) {donor_mode "send_money"}

      factory :send_books_donor, traits: [:send_books]
      factory :send_money_donor, traits: [:send_money]
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
      created_at 5.weeks.ago
      open_at 5.weeks.ago
    end

    trait :autocancelable do
      created_at 9.weeks.ago
      open_at 9.weeks.ago
    end

    factory :request_no_address do
      association :user, factory: [:student, :no_address]
    end

    factory :request_not_amazon do
      association :book, factory: [:book, :no_asin, :no_price]
    end
  end

  factory :donation do
    association :user, factory: :donor
    request

    initialize_with { request.grant! user }

    factory :donation_for_request_no_address do
      association :request, factory: :request_no_address
    end

    factory :donation_for_request_not_amazon do
      association :request, factory: :request_not_amazon
    end

    factory :donation_with_send_books_donor do
      association :user, factory: :send_books_donor
    end

    factory :donation_with_send_money_donor do
      association :user, factory: :send_money_donor
    end
  end

  factory :fulfillment do
    association :user, factory: :volunteer
    association :donation, factory: :donation_with_send_money_donor
  end

  factory :review do
    association :user, factory: :student
    book
    donation nil
    text "I really enjoyed it!"
    recommend true
  end
end
