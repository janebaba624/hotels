require 'rails_helper'

RSpec.describe Room, type: :model do

  let(:single_room) { create :room, name: 'Single Room' }
  let(:double_room) { create :room, name: 'Double Room' }

  it { should belong_to(:house).required }
  it { should have_many(:room_units).dependent(:destroy) }
  it { should have_many(:bookings).dependent(:destroy) }

  it { should validate_presence_of(:name) }

  describe 'available_between? method' do
    let(:single_room_availability) { single_room.available_between?(5.day.from_now.to_date, 7.days.from_now.to_date) }
    let(:double_room_availability) { double_room.available_between?(5.day.from_now.to_date, 7.days.from_now.to_date) }

    describe 'should return true' do
      # no room unit
      it 'when there is no booking and one room unit exists' do
        create :room_unit, room: single_room, house_id: single_room.house_id
        expect(single_room_availability).to eq true
      end

      # only one room_unit and no booking in same period
      cases = [[1, 3], [3, 5], [7, 9]]
      cases.each do |dates|
        it "when there is room unit available(case 1: #{dates.join('~')})" do
          create :room_unit, room: single_room, house_id: single_room.house_id
          create :booking, room: single_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date

          expect(single_room_availability).to eq true
        end
      end

      # 2 room units, one booking in same period and another in other perid
      cases.each do |dates|
        it "when there is room unit available(case 2: #{dates.join('~')})" do
          create :room_unit, room: single_room, house_id: single_room.house_id
          create :room_unit, room: single_room, house_id: single_room.house_id
          create :booking, room: single_room, dtstart: 5.days.from_now.to_date, dtend: 7.days.from_now.to_date
          create :booking, room: single_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date

          expect(single_room_availability).to eq true
        end
      end

      # Rooms: Single Room, Double Room
      # Room Units:
      #    Single Room: A, B
      #    Double Room: A+B
      # There is one booking for single room already but not in same period
      # should be available for both of Single and Double
      cases.each do |dates|
        it "when there is room unit available(case 3: #{dates.join('~')})" do
          a_plus_b = create :room_unit, room: double_room, house_id: double_room.house_id
          create :room_unit, room: single_room, house_id: single_room.house_id, part_of_room: a_plus_b
          create :room_unit, room: single_room, house_id: single_room.house_id, part_of_room: a_plus_b
          create :booking, room: single_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date

          expect(single_room_availability).to eq true
          expect(double_room_availability).to eq true
        end
      end

      # Rooms: Single Room, Double Room
      # Room Units:
      #    Single Room: A, B
      #    Double Room: A+B
      # There is one booking for double room already but not in same period
      # should be available for both of Single and Double
      cases.each do |dates|
        it "when there is room unit available(case 4: #{dates.join('~')})" do
          a_plus_b = create :room_unit, room: double_room, house_id: double_room.house_id
          create :room_unit, room: single_room, house_id: single_room.house_id, part_of_room: a_plus_b
          create :room_unit, room: single_room, house_id: single_room.house_id, part_of_room: a_plus_b
          create :booking, room: double_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date

          expect(single_room_availability).to eq true
          expect(double_room_availability).to eq true
        end
      end

      # Rooms: Single Room, Double Room
      # Room Units:
      #    Single Room: A, B, C
      #    Double Room: B+C
      # There is one booking for single room and one booking for double room already
      # no room available for both of Single and Double
      cases.each do |dates|
        it "when there is room unit available(case 5: #{dates.join('~')})" do
          b_plus_c = create :room_unit, room: double_room, house_id: double_room.house_id
          create :room_unit, room: single_room, house_id: single_room.house_id, part_of_room: b_plus_c
          create :room_unit, room: single_room, house_id: single_room.house_id, part_of_room: b_plus_c
          create :room_unit, room: single_room, house_id: single_room.house_id
          create :booking, room: single_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date
          create :booking, room: double_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date

          expect(single_room_availability).to eq true
          expect(double_room_availability).to eq true
        end
      end

    end

    describe 'should return false' do
      # no room unit
      it 'when there is no room units' do
        expect(single_room_availability).to eq false
      end

      # only one room_unit and one booking in same period
      cases = [[5, 7], [5, 8], [5, 6], [6, 7], [6, 8]]
      cases.each do |dates|
        it "when there is no room units available(case 1: #{dates.join('~')})" do
          create :room_unit, room: single_room, house_id: single_room.house_id
          create :booking, room: single_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date

          expect(single_room_availability).to eq false
        end
      end

      # 2 room units with 2 bookings in same period
      cases.each do |dates|
        it "when there is no room units available(case 2: #{dates.join('~')})" do
          create :room_unit, room: single_room, house_id: single_room.house_id
          create :room_unit, room: single_room, house_id: single_room.house_id
          create :booking, room: single_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date
          create :booking, room: single_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date

          expect(single_room_availability).to eq false
        end
      end

      # Rooms: Single Room, Double Room
      # Room Units:
      #    Single Room: A, B
      #    Double Room: A+B
      # There is one booking for single room already
      # no room available for both of Single and Double
      cases.each do |dates|
        it "when there is no room units available(case 3: #{dates.join('~')})" do
          a_plus_b = create :room_unit, room: double_room, house_id: double_room.house_id
          create :room_unit, room: single_room, house_id: single_room.house_id, part_of_room: a_plus_b
          create :room_unit, room: single_room, house_id: single_room.house_id, part_of_room: a_plus_b
          create :booking, room: single_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date

          expect(single_room_availability).to eq false
          expect(double_room_availability).to eq false
        end
      end

      # Rooms: Single Room, Double Room
      # Room Units:
      #    Single Room: A, B
      #    Double Room: A+B
      # There is one booking for double room already
      # no room available for both of Single and Double
      cases.each do |dates|
        it "when there is no room units available(case 4: #{dates.join('~')})" do
          a_plus_b = create :room_unit, room: double_room, house_id: double_room.house_id
          create :room_unit, room: single_room, house_id: single_room.house_id, part_of_room: a_plus_b
          create :room_unit, room: single_room, house_id: single_room.house_id, part_of_room: a_plus_b
          create :booking, room: double_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date

          expect(single_room_availability).to eq false
          expect(double_room_availability).to eq false
        end
      end

      # Rooms: Single Room, Double Room
      # Room Units:
      #    Single Room: A, B, C
      #    Double Room: B+C
      # There is one booking for single room and one booking for double room already
      # no room available for both of Single and Double
      cases.each do |dates|
        it "when there is no room units available(case 5: #{dates.join('~')})" do
          b_plus_c = create :room_unit, room: double_room, house_id: double_room.house_id
          create :room_unit, room: single_room, house_id: single_room.house_id, part_of_room: b_plus_c
          create :room_unit, room: single_room, house_id: single_room.house_id, part_of_room: b_plus_c
          create :room_unit, room: single_room, house_id: single_room.house_id
          create :booking, room: single_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date
          create :booking, room: double_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date

          expect(single_room_availability).to eq false
          expect(double_room_availability).to eq false
        end
      end

      # Rooms: Single Room, Double Room
      # Room Units:
      #    Single Room: A, B, C
      #    Double Room: B+C
      # There are 2 bookings for single room in same period
      # no room available for both of Single and Double
      cases.each do |dates|
        it "when there is no room units available(case 6: #{dates.join('~')})" do
          b_plus_c = create :room_unit, room: double_room, house_id: double_room.house_id
          create :room_unit, room: single_room, house_id: single_room.house_id, part_of_room: b_plus_c
          create :room_unit, room: single_room, house_id: single_room.house_id, part_of_room: b_plus_c
          create :room_unit, room: single_room, house_id: single_room.house_id
          create :booking, room: single_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date
          create :booking, room: single_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date

          expect(single_room_availability).to eq false
          expect(double_room_availability).to eq false
        end
      end

      # Rooms: Single Room, Double Room
      # Room Units:
      #    Single Room: A, B, C
      #    Double Room: B+C
      # There are 2 bookings for single room and one of them is reserved/locked to B already
      # no room available for Double
      cases.each do |dates|
        it "when there is no room units available(case 7: #{dates.join('~')})" do
          b_plus_c = create :room_unit, room: double_room, house_id: double_room.house_id
          create :room_unit, room: single_room, house_id: single_room.house_id, part_of_room: b_plus_c
          create :room_unit, room: single_room, house_id: single_room.house_id, part_of_room: b_plus_c
          create :room_unit, room: single_room, house_id: single_room.house_id
          create :booking, room: single_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date
          create :booking, room: single_room, dtstart: dates[0].days.from_now.to_date, dtend: dates[1].days.from_now.to_date

          expect(double_room_availability).to eq false
        end
      end

    end
  end


  describe "availability_between_dates method" do
    let(:dtstart) { 5.days.from_now.to_date }
    let(:dtend) { 35.days.from_now.to_date }
    let(:availablility) { single_room.availability_between_dates(dtstart, dtend) }

    context 'without connected room' do
      before do
        4.times.each { create :room_unit, room: single_room }
      end

      it 'length of payload should be 31 - (35-4)' do
        expect(availablility[:payload].length).to eq 31
      end

      it 'the date of first payload should be 5 days from now' do
        expect(availablility[:payload].first[:date]).to eq 5.days.from_now.to_date
      end

      it 'all value of allotment should be 4 if no booking created' do
        expect(availablility[:payload].all?{ |a| a[:allotment] == 4 }).to eq true
      end

      it 'should return desired value case 1' do
        create :booking, room: single_room, dtstart: dtstart, dtend: 15.days.from_now
        first_group = availablility[:payload][0..10]
        second_group = availablility[:payload][11..-1]
        expect(first_group.all?{ |a| a[:allotment] == 3 }).to eq true
        expect(second_group.all?{ |a| a[:allotment] == 4 }).to eq true
      end

      it 'should return desired value case 2' do
        create :booking, room: single_room, dtstart: dtstart, dtend: 15.days.from_now.to_date
        create :booking, room: single_room, dtstart: 8.days.from_now.to_date, dtend: 17.days.from_now.to_date
        create :booking, room: single_room, dtstart: 21.days.from_now.to_date, dtend: 22.days.from_now.to_date
        create :booking, room: single_room, dtstart: 13.days.from_now.to_date, dtend: 19.days.from_now.to_date

        # Day of Month         19  20  21  22  23  24  25  26  27  28  29  30  31   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27
        #                     ===============================================================================================================================================================
        # Room #1 9052        001 001 001 001 001 001 001 001 001 001 001                     003 003
        # Room #2 6066                    002 002 002 002 002 002 002 002 002 002
        # Room #3 5709                                        004 004 004 004 004 004 004
        # Room #4 5718
        #                     ---------------------------------------------------------------------------------------------------------------------------------------------------------------
        # Room #1 9052        (1)01/19~01/29, (3)02/04~02/05
        # Room #2 6066        (2)01/22~01/31
        # Room #3 5709        (4)01/27~02/02
        # Room #4 5718

        # x, assigns = single_room.assign_rooms
        # single_room.send :print_assigns, assigns, Logger.new(STDOUT)
        allotment_array = availablility[:payload].map{ |a| a[:allotment] }
        expect(allotment_array).to eq  [3,3,3,2,2,2,2,2,1,1,2,2,3,3,4,4,3,4,4,4,4,4,4,4,4,4,4,4,4,4,4]
      end
    end

    # total 4 single rooms(2 units are connected), one double room
    context 'without connected room' do
      before do
        c_plus_d = create :room_unit, room: double_room
        2.times.each { create :room_unit, room: single_room }
        create :room_unit, room: single_room, part_of_room: c_plus_d
        create :room_unit, room: single_room, part_of_room: c_plus_d
      end

      # free booking that is not reserverd yet, booking is for single room
      it 'should return desired value case 1' do
        create :booking, room: single_room, dtstart: dtstart, dtend: 15.days.from_now
        expect(availablility[:total_rooms]).to eq 4
        first_group = availablility[:payload][0..10]
        second_group = availablility[:payload][11..-1]

        expect(first_group.all?{ |a| a[:allotment] == 2 }).to eq true
        expect(second_group.all?{ |a| a[:allotment] == 3 }).to eq true
      end

      # free booking that is not reserverd yet, booking is for double room
      it 'should return desired value case 2' do
        create :booking, room: double_room, dtstart: dtstart, dtend: 15.days.from_now
        expect(availablility[:total_rooms]).to eq 4
        first_group = availablility[:payload][0..10]
        second_group = availablility[:payload][11..-1]

        expect(first_group.all?{ |a| a[:allotment] == 2 }).to eq true
        expect(second_group.all?{ |a| a[:allotment] == 3 }).to eq true
      end

      it 'should return desired value case 3' do
        create :booking, room: single_room, dtstart: dtstart, dtend: 15.days.from_now.to_date
        create :booking, room: single_room, dtstart: 8.days.from_now.to_date, dtend: 17.days.from_now.to_date
        create :booking, room: single_room, dtstart: 21.days.from_now.to_date, dtend: 22.days.from_now.to_date
        create :booking, room: double_room, dtstart: 13.days.from_now.to_date, dtend: 19.days.from_now.to_date

        # Day of Month         19  20  21  22  23  24  25  26  27  28  29  30  31   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27
        #                     ===============================================================================================================================================================
        # Room #2 6965        001 001 001 001 001 001 001 001 001 001 001                     003 003
        # Room #3 4862                    002 002 002 002 002 002 002 002 002 002
        # Room #4 8284                                        0CD 0CD 0CD 0CD 0CD 0CD 0CD
        # Room #5 8106
        #                     ---------------------------------------------------------------------------------------------------------------------------------------------------------------
        # Room #2 6965        (1)01/19~01/29, (3)02/04~02/05
        # Room #3 4862        (2)01/22~01/31
        # Room #4 8284
        # Room #5 8106

        allotment_array = availablility[:payload].map{ |a| a[:allotment] }
        expect(allotment_array).to eq  [2,2,2,1,1,1,1,1,0,0,1,1,2,2,3,3,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3]
      end
    end

    pending "should return correct value for mix of locked bookings and connected rooms"
  end

  describe "assign_rooms method" do
    pending "should fail and return false if the total number of room units is less than number of concurrent bookings"
    pending "should return optimized assignment for free bookings"
    pending "should return optimized assignment for free bookings with locked ones"
    pending "should return optimized assignment for free bookings with connected rooms"
    pending "should return optimized assignment for free bookings with connected rooms and locked bookings"
  end

end

class FakeRelation < Array
  def order(opts); self; end
end
