class CreateBookings < ActiveRecord::Migration[6.0]
  def change
    create_table :bookings do |t|
      t.datetime :dtstart
      t.datetime :dtend
      t.string :summary
      t.text :description
      t.string :status
      t.references :user
      t.references :house
      t.references :room
      t.references :room_unit

      t.timestamps
    end
  end
end
