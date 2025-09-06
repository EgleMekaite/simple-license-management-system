# frozen_string_literal: true

class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products, id: :uuid do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps
    end
  end
end
