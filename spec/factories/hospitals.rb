# frozen_string_literal: true

FactoryBot.define do
  factory :hospital do
    warehouse
    user

    name { "KBNF" }
  end
end
