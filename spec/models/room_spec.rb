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
    context 'with connected room' do
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
        #                     2,  2,  2,  1,  1,  1,  1,  1,  0,  0,  1,  1,  2,  2,  3,  3,  2,  3,  3,  3,3,3,3,3,3,3,3,3,3,3,3
        # Room #2 6965        (1)01/19~01/29, (3)02/04~02/05
        # Room #3 4862        (2)01/22~01/31
        # Room #4 8284
        # Room #5 8106

        allotment_array = availablility[:payload].map{ |a| a[:allotment] }
        expect(allotment_array).to eq  [2,2,2,1,1,1,1,1,0,0,1,1,2,2,3,3,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3]
      end
    end

    # total 4 single rooms(2 units are connected), one double room
    context "with mix of locked bookings and connected rooms" do
      let (:c_plus_d) { create :room_unit, room: double_room }
      before do
        2.times.each { create :room_unit, room: single_room }
        create :room_unit, room: single_room, part_of_room: c_plus_d
      end

      it 'should return desired value' do
        c = create :room_unit, room: single_room, part_of_room: c_plus_d
        create :booking, room: single_room, dtstart: dtstart, dtend: 15.days.from_now.to_date
        create :booking, room: single_room, dtstart: 8.days.from_now.to_date, dtend: 17.days.from_now.to_date
        create :booking, room: single_room, dtstart: 21.days.from_now.to_date, dtend: 22.days.from_now.to_date, room_unit: c
        create :booking, room: double_room, dtstart: 13.days.from_now.to_date, dtend: 19.days.from_now.to_date

        # Day of Month         21  22  23  24  25  26  27  28  29  30  31   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29
        #                     ===============================================================================================================================================================
        # Room #1 3913        001 001 001 001 001 001 001 001 001 001 001
        # Room #2 3508                    002 002 002 002 002 002 002 002 002 002
        # Room #4 7063                                        0CD 0CD 0CD 0CD 0CD 0CD 0CD
        # Room #5 3232                                                                        003 003
        #                     ---------------------------------------------------------------------------------------------------------------------------------------------------------------
        #                     2,  2,  2,  1,  1,  1,  1,  1,  0,  0,  1,  1,  2,  2,  3,  3,  2,  3,  3,  3,3,3,3,3,3,3,3,3,3,3,3
        # Room #1 3913        (1)01/21~01/31
        # Room #2 3508        (2)01/24~02/02
        # Room #4 7063
        # Room #5 3232        (3)02/06~02/07
        
        # x, assigns = single_room.assign_rooms
        # single_room.send :print_assigns, assigns, Logger.new(STDOUT)
        allotment_array = availablility[:payload].map{ |a| a[:allotment] }
        expect(allotment_array).to eq  [2,2,2,1,1,1,1,1,0,0,1,1,2,2,3,3,2,3,3,3,3,3,3,3,3,3,3,3,3,3,3]
      end
    end
  end

  describe "assign_rooms method" do
    let (:single_room_assigns) { single_room.assign_rooms }
    let (:double_room_assigns) { double_room.assign_rooms }
    let (:single_room_assigns_with_new_booking) { single_room.assign_rooms([build(:booking, room: single_room)]) }
    let (:double_room_assigns_with_new_booking) { double_room.assign_rooms([build(:booking, room: double_room)]) }

    context 'should fail and return false if the total number of room units is less than number of concurrent bookings' do
      before do
        3.times.each { create :room_unit, room: single_room }
      end

      # try new booking when there are 3 concurrent bookings for 3 room units
      it 'case 1' do
        3.times.each { create :booking, room: single_room }
        expect(single_room_assigns_with_new_booking[0]).to eq false
      end

      # try new booking when there are 4 concurrent bookings for 5 room units that 2 of them are connected
      it 'case 2' do
        a_plus_b = create :room_unit, room: double_room
        2.times.each { create :room_unit, room: single_room, part_of_room: a_plus_b }
        4.times.each { create :booking, room: single_room }
        expect(single_room_assigns_with_new_booking[0]).to eq false
      end

      # same with case 2 except new booking is for double room
      it 'case 3' do
        a_plus_b = create :room_unit, room: double_room
        2.times.each { create :room_unit, room: single_room, part_of_room: a_plus_b }
        4.times.each { create :booking, room: single_room }
        expect(double_room_assigns_with_new_booking[0]).to eq false
      end

      # 5 single rooms(2 of them are connected), 1 double room, 1 booking for double, 3 booking for single
      # no new booking available for both of single, double
      it 'case 4' do
        a_plus_b = create :room_unit, room: double_room
        2.times.each { create :room_unit, room: single_room, part_of_room: a_plus_b }
        3.times.each { create :booking, room: single_room }
        create :booking, room: double_room
        expect(single_room_assigns_with_new_booking[0]).to eq false
        expect(double_room_assigns_with_new_booking[0]).to eq false
      end

      # 5 single rooms(2 of them are connected), 1 double room, 3 booking for single and one is reserved for connected room
      # no new booking available for double
      it 'case 5' do
        a_plus_b = create :room_unit, room: double_room
        a = create :room_unit, room: single_room, part_of_room: a_plus_b
        b = create :room_unit, room: single_room, part_of_room: a_plus_b
        2.times.each { create :booking, room: single_room }
        create :booking, room: single_room, room_unit: a
        expect(double_room_assigns_with_new_booking[0]).to eq false
      end
    end

    context 'should return true for free bookings + new booking' do
      before do
        3.times.each { create :room_unit, room: single_room }
      end

      # try new booking when there are 2 concurrent bookings for 3 room units
      it 'case 1' do
        2.times.each { create :booking, room: single_room }
        expect(single_room_assigns_with_new_booking[0]).to eq true
        expect(single_room_assigns_with_new_booking[1].values.map(&:count)).to eq [1, 1, 1]
        expect(single_room_assigns_with_new_booking[1].values.flatten.map(&:id)).to eq [1, 2, nil]
      end

      # try new booking when there are 3 concurrent bookings for 5 room units that 2 of them are connected
      it 'case 2' do
        a_plus_b = create :room_unit, room: double_room
        2.times.each { create :room_unit, room: single_room, part_of_room: a_plus_b }
        3.times.each { create :booking, room: single_room }
        expect(single_room_assigns_with_new_booking[0]).to eq true
        expect(single_room_assigns_with_new_booking[1].values.map(&:count)).to eq [1, 1, 1, 1, 0]
        expect(single_room_assigns_with_new_booking[1].values.flatten.map(&:id)).to eq [1, 2, 3, nil]
      end

      # same with case 2 except new booking is for double room
      it 'case 3' do
        a_plus_b = create :room_unit, room: double_room
        2.times.each { create :room_unit, room: single_room, part_of_room: a_plus_b }
        3.times.each { create :booking, room: single_room }
        expect(double_room_assigns_with_new_booking[0]).to eq true
        expect(double_room_assigns_with_new_booking[1].values.map(&:count)).to eq [1]
        expect(double_room_assigns_with_new_booking[1].values.flatten.map(&:id)).to eq [nil]
      end
    end

    describe "should return optimized assignment" do
      let (:bookings_json) do
        JSON.parse <<-EOF_BOOKING_SEED
          [
            {"dtstart":"2020-10-1",  "dtend":"2020-10-3",  "id":1, "room_unit_id":3 },
            {"dtstart":"2020-10-1",  "dtend":"2020-10-4",  "id":2                    },
            {"dtstart":"2020-10-3",  "dtend":"2020-10-6",  "id":3                    },
            {"dtstart":"2020-10-3",  "dtend":"2020-10-8",  "id":4, "room_unit_id":5 },
            {"dtstart":"2020-10-4",  "dtend":"2020-10-8",  "id":5, "room_unit_id":3 },
            {"dtstart":"2020-10-8",  "dtend":"2020-10-12", "id":6                    },
            {"dtstart":"2020-10-9",  "dtend":"2020-10-20", "id":7, "room_unit_id":3 },
            {"dtstart":"2020-10-15", "dtend":"2020-10-20", "id":8                    },
            {"dtstart":"2020-10-21", "dtend":"2020-10-30", "id":9                    }
          ]
        EOF_BOOKING_SEED
      end

      it 'for free bookings' do
        5.times.each { create :room_unit, room: single_room }
        bookings_json.each {|b| create :booking, b.merge(room: single_room, room_unit_id: nil) }

        # Day of Month          1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31   1   2   3   4   5   6   7   8   9
        #                     ===============================================================================================================================================================
        # Room #1 5828        001 001/004 004 004 004 004 004 007 007 007 007 007 007 007 007 007 007 007 007 009 009 009 009 009 009 009 009 009 009
        # Room #2 2299        002 002 002/005 005 005 005/006 006 006 006 006         008 008 008 008 008 008
        # Room #3 3371                003 003 003 003
        # Room #4 6903
        # Room #5 8232
        #                     ---------------------------------------------------------------------------------------------------------------------------------------------------------------
        # Room #1 5828        (1)10/01~10/03, (4)10/03~10/08, (7)10/09~10/20, (9)10/21~10/30
        # Room #2 2299        (2)10/01~10/04, (5)10/04~10/08, (6)10/08~10/12, (8)10/15~10/20
        # Room #3 3371        (3)10/03~10/06
        # Room #4 6903
        # Room #5 8232

        # single_room.send :print_assigns, single_room_assigns[1], Logger.new(STDOUT)
        expect(single_room_assigns[0]).to eq true
        assigns = single_room_assigns[1].inject({}) { |h, kv| h.merge!(kv[0] => kv[1].map(&:id)) }
        expect(assigns).to eq({ 1=>[1, 4, 7, 9], 2=>[2, 5, 6, 8], 3=>[3], 4=>[], 5=>[] })
      end

      it 'for free bookings with locked ones' do
        5.times.each { create :room_unit, room: single_room }
        bookings_json.each {|b| create :booking, b.merge(room: single_room) }

        # Day of Month          1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31   1   2   3   4   5   6   7   8   9
        #                     ===============================================================================================================================================================
        # Room #1 6543        002 002 002 002             006 006 006 006 006         008 008 008 008 008 008 009 009 009 009 009 009 009 009 009 009
        # Room #2 9061                003 003 003 003
        # Room #3 5762        001 001 001 005 005 005 005 005 007 007 007 007 007 007 007 007 007 007 007 007
        # Room #4 3591
        # Room #5 7192                004 004 004 004 004 004
        #                     ---------------------------------------------------------------------------------------------------------------------------------------------------------------
        # Room #1 6543        (2)10/01~10/04, (6)10/08~10/12, (8)10/15~10/20, (9)10/21~10/30
        # Room #2 9061        (3)10/03~10/06
        # Room #3 5762        (1)10/01~10/03, (5)10/04~10/08, (7)10/09~10/20
        # Room #4 3591
        # Room #5 7192        (4)10/03~10/08

        # single_room.send :print_assigns, single_room_assigns[1], Logger.new(STDOUT)
        expect(single_room_assigns[0]).to eq true
        assigns = single_room_assigns[1].inject({}) { |h, kv| h.merge!(kv[0] => kv[1].map(&:id)) }
        expect(assigns).to eq({ 1=>[2, 6, 8, 9], 2=>[3], 3=>[1, 5, 7], 4=>[], 5=>[4] })
      end

      # the result should be almost same with first case(free bookings) except connected room should not be assigned for later use
      # in other word, we will assign single rooms first and assign connected rooms if needs more rooms
      it 'for free bookings with connected rooms' do
        create :room_unit, room: single_room, part_of_room_id: 1000
        create :room_unit, room: single_room, part_of_room_id: 1000
        3.times.each { create :room_unit, room: single_room }
        a_plus_b = create :room_unit, room: double_room, id: 1000
        bookings_json.each {|b| create :booking, b.merge(room: single_room, room_unit_id: nil) }

        # Day of Month          1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31   1   2   3   4   5   6   7   8   9
        #                     ===============================================================================================================================================================
        # Room #1 4790
        # Room #2 1283
        # Room #3 3840        001 001/004 004 004 004 004 004 007 007 007 007 007 007 007 007 007 007 007 007 009 009 009 009 009 009 009 009 009 009
        # Room #4 8938        002 002 002/005 005 005 005/006 006 006 006 006         008 008 008 008 008 008
        # Room #5 9980                003 003 003 003
        #                     ---------------------------------------------------------------------------------------------------------------------------------------------------------------
        # Room #1 4790
        # Room #2 1283
        # Room #3 3840        (1)10/01~10/03, (4)10/03~10/08, (7)10/09~10/20, (9)10/21~10/30
        # Room #4 8938        (2)10/01~10/04, (5)10/04~10/08, (6)10/08~10/12, (8)10/15~10/20
        # Room #5 9980        (3)10/03~10/06

        # single_room.send :print_assigns, single_room_assigns[1], Logger.new(STDOUT)
        expect(single_room_assigns[0]).to eq true
        assigns = single_room_assigns[1].inject({}) { |h, kv| h.merge!(kv[0] => kv[1].map(&:id)) }
        expect(assigns).to eq({ 1=>[], 2=>[], 3=>[1, 4, 7, 9], 4=>[2, 5, 6, 8], 5=>[3] })
      end

      it 'for free bookings with connected rooms and locked bookings' do
        create :room_unit, room: single_room, part_of_room_id: 1000
        create :room_unit, room: single_room, part_of_room_id: 1000
        3.times.each { create :room_unit, room: single_room }
        a_plus_b = create :room_unit, room: double_room, id: 1000
        bookings_json.each {|b| create :booking, b.merge(room: single_room) }

        # Day of Month          1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20  21  22  23  24  25  26  27  28  29  30  31   1   2   3   4   5   6   7   8   9
        #                     ===============================================================================================================================================================
        # Room #1 4704                003 003 003 003
        # Room #2 4943
        # Room #3 4389        001 001 001 005 005 005 005 005 007 007 007 007 007 007 007 007 007 007 007 007 009 009 009 009 009 009 009 009 009 009
        # Room #4 9103        002 002 002 002             006 006 006 006 006         008 008 008 008 008 008
        # Room #5 6215                004 004 004 004 004 004
        #                     ---------------------------------------------------------------------------------------------------------------------------------------------------------------
        # Room #1 4704        (3)10/03~10/06
        # Room #2 4943
        # Room #3 4389        (1)10/01~10/03, (5)10/04~10/08, (7)10/09~10/20, (9)10/21~10/30
        # Room #4 9103        (2)10/01~10/04, (6)10/08~10/12, (8)10/15~10/20
        # Room #5 6215        (4)10/03~10/08

        # single_room.send :print_assigns, single_room_assigns[1], Logger.new(STDOUT)
        expect(single_room_assigns[0]).to eq true
        assigns = single_room_assigns[1].inject({}) { |h, kv| h.merge!(kv[0] => kv[1].map(&:id)) }
        expect(assigns).to eq({ 1=>[3], 2=>[], 3=>[1, 5, 7, 9], 4=>[2, 6, 8], 5=>[4] })
      end
    end
  end

end
