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

      trait(:no_address) {address ""}
    end

    factory :donor do
      sequence(:name) {|n| "Donor #{n}"}

      trait(:send_books) {donor_mode "send_books"}
      trait(:send_money) {donor_mode "send_money"}

      factory :send_books_donor, traits: [:send_books]
      factory :send_money_donor, traits: [:send_money]
    end
  end

  factory :book do
    sequence(:title) {|n| "Book #{n}"}
    price 10

    trait(:no_price) {price nil}
  end

  factory :request do
    association :user, factory: :student
    book
    reason "I've heard so much about this"
    pledge "1"

    factory :request_no_address do
      association :user, factory: [:student, :no_address]
    end

    factory :request_no_price do
      association :book, factory: [:book, :no_price]
    end
  end

  factory :donation do
    request
    association :user, factory: :donor

    initialize_with { request.grant! user }

    factory :donation_for_request_no_address do
      association :request, factory: :request_no_address
    end

    factory :donation_for_request_no_price do
      association :request, factory: :request_no_price
    end

    factory :donation_with_send_books_donor do
      association :user, factory: :send_books_donor
    end

    factory :donation_with_send_money_donor do
      association :user, factory: :send_money_donor
    end
  end

  factory :review do
    association :user, factory: :student
    book
    text "I really enjoyed it!"
    recommend true
  end
end
