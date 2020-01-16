class Room < ApplicationRecord
  belongs_to :house
  has_many :room_units, dependent: :destroy
  has_many :bookings, dependent: :destroy

  validates_presence_of :name

  def availability_between_dates(dtstart, dtend)
    dtstart = Date.parse(dtstart) if dtstart.is_a?(String)
    dtend = Date.parse(dtend) if dtend.is_a?(String)

    nb_units = room_units.count

    is_assigned, assigns = assign_rooms

    raise "Unexpected Error, failed to assign rooms" unless is_assigned

    connected_rooms_info = room_units.where.not(part_of_room_id: nil).group(:part_of_room_id).count

    {
      total_rooms: room_units.count,
      start_date: dtstart,
      end_date: dtend,
      payload: (dtstart..dtend).map do |date|
        removed_due_same_lvl_locking = []
        available_rooms = assigns.select { |room_unit_id, booking_set|
          room_unit = RoomUnit.find(room_unit_id) # RoomUnit.find(room_unit_id)
          connected_count = connected_rooms_info[room_unit.part_of_room_id].to_i
          if room_unit.part_of_room_id and connected_count >= 2
            next if removed_due_same_lvl_locking.include?(room_unit.part_of_room_id)
            removed_due_same_lvl_locking << room_unit.part_of_room_id
          end

          if room_unit.part_of_room_id
            same_lvl_connected_bookings = room_units.where(part_of_room_id: room_unit.part_of_room_id).map do |ru|
              assigns[ru.id]
            end.flatten
          else
            same_lvl_connected_bookings = []
          end

          connected_bookings = connected_bookings_for(room_unit)
          !(same_lvl_connected_bookings + booking_set + connected_bookings).any? { |b| b.dtstart <= date && b.dtend > date }
        }.keys

        {
          date: date,
          allotment: available_rooms.count,
          rooms: available_rooms.join(', ') #.map {|id| RoomUnit.find(id).room_no}.join(", ")
        }
      end
    }
  end

  def available_between?(dtstart, dtend, booking_id = nil, room_unit_id = nil)
    new_booking = Booking.new(id: booking_id, dtstart: dtstart, dtend: dtend, room: self, room_unit_id: room_unit_id)
    return false unless assign_rooms([new_booking])[0]

    leaf_rooms = []
    room_units.joins(:consist_of_rooms).group(:id).each do |u|
      leaf_rooms += u.consist_of_rooms.map(&:room)
    end
    leaf_rooms.uniq!

    return true if leaf_rooms.empty?
    leaf_rooms.all? { |r| r.assign_rooms([new_booking])[0] }
  end

  def assign_rooms(extra_bookings = [])
    nb_rooms = room_units.count
    assigns = room_units.inject({}) { |h, u| h.merge!(u.id => []) }
    # TODO: past bookings should not be considered due performance
    if extra_bookings.all? { |b| b.new_record? }
      room_bookings = Booking.where(room_id: self.id).to_a
    else
      room_bookings = Booking.where(room_id: self.id)
                            .where(Booking.arel_table[:id].not_in extra_bookings.map(&:id).compact).to_a
    end
    sorted_bookings = (room_bookings + extra_bookings.select{|b| b.room_id == self.id}).sort { |a, b| a.dtstart <=> b.dtstart }

    return [true, assigns] if sorted_bookings.empty? 

    room_units.order(part_of_room_id: :asc).each do |room_unit|
      nb_bookings = sorted_bookings.count
      break if sorted_bookings.empty?

      # get bookings for double(triple or more) rooms first
      connected_rooms = connected_rooms_for(room_unit)
      connected_bookings = connected_bookings_for(room_unit, extra_bookings)
      return [false, assigns] unless connected_bookings

      graph = DijkstraGraph.new
      path_nodes = (-1...nb_bookings).map do |i|
        nodes = []
        locked_bookings = sorted_bookings.select { |b| b.room_unit_id == room_unit.id }
        end_date = (i == -1) ? sorted_bookings.first.dtstart : sorted_bookings[i].dtend
        for j in ((i + 1)...nb_bookings) do
          next if sorted_bookings[j].reserved? && sorted_bookings[j].room_unit_id != room_unit.id

          # can't be relocated due locked or 
          is_conflicting_with_locked_booking = locked_bookings.any? { |lb|
            (lb.id != sorted_bookings[j].id) &&
            ((lb.dtstart < sorted_bookings[j].dtend && sorted_bookings[j].dtend <= lb.dtend) ||
            (lb.dtstart <= sorted_bookings[j].dtstart && sorted_bookings[j].dtstart < lb.dtend) ||
            (sorted_bookings[j].dtstart < lb.dtstart && lb.dtend < sorted_bookings[j].dtend))
          }

          if is_conflicting_with_locked_booking
            next if !sorted_bookings[j].reserved?
            return [false, assigns]
          end

          # not available due bookings with connected rooms
          # case 1: double room booking.
          # e.g. Both of A and B can't be booked when [A+B] is booked
          next if connected_bookings.any? { |b|
            (b.dtstart < sorted_bookings[j].dtend && sorted_bookings[j].dtend <= b.dtend) ||
            (b.dtstart <= sorted_bookings[j].dtstart && sorted_bookings[j].dtstart < b.dtend) ||
            (sorted_bookings[j].dtstart < b.dtstart && b.dtend < sorted_bookings[j].dtend)
          }

          # case 2: booking for connected room.
          # case 2.1: both A and B are included in same room 
          # case 2.2: A.room_id and B.room_id is diffent
          next if connected_rooms.any? { |cr|
            assigns[cr.id].any? { |b| 
              (b.dtstart < sorted_bookings[j].dtend && sorted_bookings[j].dtend <= b.dtend) ||
              (b.dtstart <= sorted_bookings[j].dtstart && sorted_bookings[j].dtstart < b.dtend) ||
              (sorted_bookings[j].dtstart < b.dtstart && b.dtend < sorted_bookings[j].dtend)
            }
          }

          # in case of room consists of part rooms
          if sorted_bookings[j].new_record?
            does_not_affect_sub_rooms = room_unit.consist_of_rooms.group(:room_id).any? do |sr|
              test_room = sorted_bookings[j].dup
              test_room.room = sr.room
              test_room.room_unit = sr
              !sr.room.assign_rooms([test_room])[0]
            end
            next if does_not_affect_sub_rooms
          end

          if end_date <= sorted_bookings[j].dtstart
            graph.add_edge(i, j, ((sorted_bookings[j].dtstart - end_date) / 1.day).to_i)
            nodes.push [i, j, ((sorted_bookings[j].dtstart - end_date) / 1.day).to_i]
          end
        end
        nodes
      end

      paths = graph.shortest_paths(-1)

      # sort by efficient(booking count desc and free_dates asc)
      best_path = paths.select{ |p| p[0] != -1 }.sort{ |a, b| [b[1].count, -b[2]] <=> [a[1].count, -a[2]]}.first
      best_path && best_path[1].each_index{|index| assigns[room_unit.id].push sorted_bookings.delete_at(best_path[1][index] - index)}
    end

    print_assigns(assigns) if Rails.env.development?

    if Rails.env.development? and sorted_bookings.any?
      logger.info "---------------------------"
      logger.info sorted_bookings.map {|x| "#{"%4d" % x.id}: #{x.dtstart.strftime("%Y-%m-%d")} ~ #{x.dtend.strftime("%Y-%m-%d")}"}
      logger.info "---------------------------"
    end

    [sorted_bookings.empty?, assigns]
  end

  private

  def connected_rooms_for(room_unit)
    @_room_hash = {}
    _connected_rooms_for(room_unit)
  end

  def _connected_rooms_for(room_unit)
    return [] unless room_unit.part_of_room_id
    same_lvl_rooms = room_unit.part_of_room.consist_of_rooms.where.not(id: room_unit.id)
    same_lvl_rooms + same_lvl_rooms.map { |r|
      if @_room_hash[r.id].nil?
        @_room_hash[r.id] = []
        @_room_hash[r.id] = _connected_rooms_for(r)
      else
        @_room_hash[r.id]
      end
    }.flatten + _connected_rooms_for(room_unit.part_of_room)
  end

  # return nil if no room available
  # return [](empty array) for rooms not connected
  def connected_bookings_for(room_unit, extra_bookings = [])
    @_bookings_by_room = {}
    @_bookings_by_unit = {}
    _connected_bookings_for(room_unit, extra_bookings)
  end

  def _connected_bookings_for(room_unit, extra_bookings)
    return [] unless room_unit.part_of_room_id
    @_bookings_by_room[room_unit.part_of_room.room_id] ||= begin
      is_assigned, assigns = room_unit.part_of_room.room.assign_rooms(extra_bookings)
      return nil unless is_assigned
      assigns
    end

    upper_connected_ones = _connected_bookings_for(room_unit.part_of_room, extra_bookings)
    return [] if upper_connected_ones.nil?
    same_lvl_rooms = room_unit.part_of_room.consist_of_rooms.where.not(id: room_unit.id).to_a
    connected_ones = same_lvl_rooms.map { |cr|
      if @_bookings_by_unit[cr.id].nil?
        @_bookings_by_unit[cr.id] = []
        @_bookings_by_unit[cr.id] = (_connected_bookings_for(cr, extra_bookings) || [])
      else
        @_bookings_by_unit[cr.id]
      end 
    }.flatten
    @_bookings_by_room[room_unit.part_of_room.room_id][room_unit.part_of_room_id] + upper_connected_ones
  end

  def print_assigns(assigns, log_handle = nil)
    bookings_index = bookings.index_by(&:id)
    num_of_rooms = room_units.count

    global_dtstart = bookings.order(dtstart: :asc).first&.dtstart
    global_dtstart ||= assigns.values.first[0].dtstart rescue Date.today

    log_handle ||= logger

    lines = []
    assigns.each do |room_id, booking_set|
      last_day = global_dtstart - 1.day
      room_name = "Room ##{room_id} " + RoomUnit.find(room_id).room_no
      line = room_name + (" " * (20 - room_name.length))

      booking_set.each do |booking|
        start = booking.dtstart
        period = ((booking.dtend - booking.dtstart) / 1.day).to_i + 1

        line = line[0..-6] + '/' if (last_day == start)
        if start > last_day + 1.day
          line += "    " * ((start - 1.day - last_day) / 1.day).to_i
        end
        line += ((booking.reserved? ? "%03d " : "%03d ") % (booking.id)) * period
        last_day = start + (period - 1).days
      end
      lines.push line
    end

    # lines.push "\r\n"
    line = " " * 20
    line += ("----" * 40)[0..-2]
    lines.push line
    # lines.push "\r\n"
    assigns.each do |room_id, booking_set|
      room_name = "Room ##{room_id} #{RoomUnit.find(room_id).room_no}"
      line = room_name + (" " * (20 - room_name.length))
      booking_dates = []
      for booking in booking_set do
        start = booking.dtstart.strftime("%m/%d")
        stop = booking.dtend.strftime("%m/%d")
        booking_dates.push "(#{booking.id})#{start}~#{stop}"
      end
      line += booking_dates.join(", ")
      lines.push line
    end

    log_handle<< "\r\nDay of Month" + (" " * 8)
    (0...40).each do |day|
      log_handle<< "%3d " % (global_dtstart + day.days).day
    end

    log_handle<< "\r\n"
    log_handle<< " " * 20
    log_handle<< ("====" * 40)[0..-2]
    log_handle<< "\r\n"
    log_handle<< lines.join("\r\n")
    log_handle<< "\r\n"
  end

end
