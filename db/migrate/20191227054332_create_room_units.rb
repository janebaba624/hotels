class CreateRoomUnits < ActiveRecord::Migration[6.0]
  def change
    create_table :room_units do |t|
      t.string :room_no
      t.references :room
      t.references :house

      t.timestamps
    end
  end
end
