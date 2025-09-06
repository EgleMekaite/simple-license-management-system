# frozen_string_literal: true

class CreateLicenseAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :license_assignments, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :product, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
    add_index :license_assignments, [:account_id, :user_id, :product_id], unique: true, name: "index_license_assignments_on_account_user_product"
  end
end
