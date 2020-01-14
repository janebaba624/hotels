FactoryBot.define do
  factory :room do
    house
    name { Faker::GameOfThrones.character }
  end
end
