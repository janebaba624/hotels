require 'rails_helper'

RSpec.describe RoomUnit, type: :model do

  it { should belong_to(:house).required }
  it { should belong_to(:room).required }
  it { should belong_to(:part_of_room).class_name('RoomUnit').optional }
  it { should have_many(:consist_of_rooms).class_name('RoomUnit').with_foreign_key(:part_of_room_id) }

  it { should validate_presence_of(:room_no) }

end
