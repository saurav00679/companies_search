class CreateCompanies < ActiveRecord::Migration[7.0]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :location
      t.index [:name, :location], unique: true

      t.timestamps
    end
  end
end
