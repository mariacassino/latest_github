class CreateProjects < ActiveRecord::Migration[5.2]
  def change
    create_table :projects do |t|
      t.string :name
      t.string :owner
      t.string :url
      t.integer :stars

      t.timestamps
    end
  end
end
