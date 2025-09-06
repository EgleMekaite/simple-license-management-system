# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.references :account, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
    add_index :users, "LOWER(email)", unique: true, name: "index_users_on_lower_email"
  end
end
