# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:first_name) { |n| "First name #{n}" }
    sequence(:last_name) { |n| "Last name #{n}" }
    password { "1234567890" }
    phone { "1234567890" }
    sequence(:email) { |n| "user-#{n}@kbnf.org" }
  end
end
