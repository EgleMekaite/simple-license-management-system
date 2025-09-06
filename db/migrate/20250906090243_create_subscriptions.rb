# frozen_string_literal: true

class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :uuid
      t.integer :number_of_licenses, null: false, default: 0
      t.datetime :issued_at, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :subscriptions, [:account_id, :product_id], unique: true
  end
end
