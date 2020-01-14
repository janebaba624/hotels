FactoryBot.define do
  factory :house do
    name { Faker::GameOfThrones.character }
  end
end
