FactoryBot.define do
  factory :room_unit do
    house
    room
    room_no { Faker::Number.number(4) }
  end
end
