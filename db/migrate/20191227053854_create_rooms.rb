class CreateRooms < ActiveRecord::Migration[6.0]
  def change
    create_table :rooms do |t|
      t.string :name
	    t.boolean :is_master
      t.references :house
 
      t.timestamps
    end
  end
end
