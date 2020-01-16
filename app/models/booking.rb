class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :house
  belongs_to :room
  belongs_to :room_unit, optional: true

  validate :room_should_be_available
  validates_presence_of :dtstart, :dtend

  def reserved?
    room_unit.present?
  end


  private

  def room_should_be_available
    return if !room || !dtstart || !dtend # return for locked booking or invalid room

    unless room.available_between?(dtstart, dtend, id, room_unit_id)
      errors.add :room_id, "is not available"
    end
  end
end
