FactoryBot.define do
  factory :booking do
    user
    house
    room
    dtstart   { Date.today }
    dtend     { 3.days.from_now }
  end
end
