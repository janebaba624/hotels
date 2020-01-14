class AddComposedOfToRoomUnits < ActiveRecord::Migration[6.0]
  def change
    add_column :room_units, :part_of_room_id, :integer, index: true
  end
end
