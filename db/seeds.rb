require 'faker'

puts 'create houses'

house = House.create!(is_master: true,
  status: :listed,
  name: Faker::GameOfThrones.character,
  address: Faker::Address.full_address,
)

guest = User.create(
  name: Faker::Name.name,
  email: Faker::Internet.email,
  phone: Faker::PhoneNumber.cell_phone
)

single_room1 = house.rooms.create!(
    is_master: true,
    name: "Single Room Class A"
  )

single_room2 = house.rooms.create!(
    is_master: true,
    name: "Single Room Class B"
  )

# double_room = house.rooms.create!(
#     is_master: true,
#     name: "Double Room"
#   )

# 3.times.each do |i|
#   ('A'..'D').each do |l|
#     unit = single_room1.room_units.find_or_create_by!(room_no: "#{"A%02d" % (i + 1)}#{l}", house: house)
#   end
# end

# 3.times.each do |i|
#   ('A'..'B').each do |l|
#     unit = single_room2.room_units.find_or_create_by!(room_no: "#{"B%02d" % (i + 1)}#{l}", house: house)
#   end
# end

# room_ab02 = double_room.room_units.create!(room_no: "02A", house: house)
# RoomUnit.find_by_room_no('A02A').update_attributes part_of_room_id: room_ab02.id
# RoomUnit.find_by_room_no('B02A').update_attributes part_of_room_id: room_ab02.id

# ra02cd = double_room.room_units.create!(room_no: "A02C+D", house: house)
# RoomUnit.find_by_room_no('A02C').update_attributes part_of_room_id: ra02cd.id
# RoomUnit.find_by_room_no('A02D').update_attributes part_of_room_id: ra02cd.id

# booking1 = Booking.create(
#   dtstart: Date.today + 1.day,
#   dtend: Date.today + 3.day,
#   house: house,
#   user: guest,
#   room: room_ab02.room,
#   room_unit: nil
# )

# booking2 = Booking.create(
#   dtstart: Date.today + 2.day,
#   dtend: Date.today + 3.day,
#   house: house,
#   user: guest,
#   room: ra02cd.room,
#   room_unit: nil
# )

# booking3 = Booking.create(
#   dtstart: Date.today + 2.day,
#   dtend: Date.today + 3.day,
#   house: house,
#   user: guest,
#   room: single_room1,
#   room_unit: nil
# )

# 200.times.each do
#   future_dtstart = Date.current.tomorrow + rand(10)
#   future_dtend = future_dtstart + (1 + rand(10))
#   past_dtend = Date.current.yesterday - rand(10)
#   past_dtstart = past_dtend - (1 + rand(10))
#   [[future_dtstart, future_dtend], [past_dtstart, past_dtend]].each do |dtstart, dtend|
#     room = [single_room1, single_room2, double_room].sample
#     booking = Booking.create(
#       house: house,
#       room: room,
#       summary: Faker::GameOfThrones.character,
#       description: Faker::Lorem.paragraph,
#       status: :confirmed,
#       user: guest,
#       dtstart: dtstart,
#       dtend: dtend
#     )
#   end
# end


bookings = JSON.parse <<-EOBOOKINGS
[{
"checkin": "2017-10-1",
"checkout": "2017-10-3",
"room_id": 3,
"id": 1
},
{
"checkin": "2017-10-1",
"checkout": "2017-10-4",
"id": 2
},
{
"checkin": "2017-10-3",
"checkout": "2017-10-6",
"id": 3
},
{
"checkin": "2017-10-3",
"checkout": "2017-10-8",
"room_id": 5,
"id": 4
},
{
"checkin": "2017-10-4",
"checkout": "2017-10-8",
"room_id": 3,
"id": 5
},
{
"checkin": "2017-10-8",
"checkout": "2017-10-12",
"id": 6
},
{
"checkin": "2017-10-9",
"checkout": "2017-10-20",
"room_id": 3,
"id": 7
},
{
"checkin": "2017-10-15",
"checkout": "2017-10-20",
"id": 8
},
{
"checkin": "2017-10-21",
"checkout": "2017-10-30",
"id": 9
}]
EOBOOKINGS

10.times.each do |i|
  single_room1.room_units.find_or_create_by!(room_no: "#{"A%02d" % (i + 1)}", house: house)
end

bookings.each do |b|
  booking = Booking.create(
    id: b['id'],
    house: house,
    room: single_room1,
    summary: Faker::GameOfThrones.character,
    description: Faker::Lorem.paragraph,
    status: :confirmed,
    user: guest,
    dtstart: b['checkin'],
    dtend: b['checkout'],
    room_unit_id: b['room_id']
  )
end
