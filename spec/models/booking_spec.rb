require 'rails_helper'

RSpec.describe Booking, type: :model do

  let(:user) { build_stubbed :user }
  let(:room) { build_stubbed :room }
  let(:house) { build_stubbed :house }
  let(:booking) { build :booking, room: room }

  it { should belong_to(:user).required }
  it { should belong_to(:house).required }
  it { should belong_to(:room).required }
  it { should belong_to(:room_unit).optional }

  it { should validate_presence_of(:dtstart) }
  it { should validate_presence_of(:dtend) }

  describe 'record should call' do
    before { expect(booking).to receive(:room_should_be_available) }

    it 'room_should_be_available for validation' do
      booking.valid?
    end
  end

  describe 'record should not be valid' do
    before { allow(room).to receive(:available_between?).and_return false }

    it 'when there is no room available' do
      expect(booking).to_not be_valid
      expect(booking.errors.full_messages).to include "Room is not available"
    end
  end

  describe 'record should be valid' do
    before { allow(room).to receive(:available_between?).and_return true }

    it 'when there is no room available' do
      expect(booking).to be_valid
    end
  end

end
