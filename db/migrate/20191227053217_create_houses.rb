class CreateHouses < ActiveRecord::Migration[6.0]
  def change
    create_table :houses do |t|
      t.string :name
      t.string :address
      t.string :status
      t.boolean :is_master

      t.timestamps
    end
  end
end
