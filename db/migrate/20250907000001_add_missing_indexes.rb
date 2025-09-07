# frozen_string_literal: true

class AddMissingIndexes < ActiveRecord::Migration[7.1]
  def change
    # Speeds up lookups like:
    # LicenseAssignment.where(account_id: ?, product_id: ?)
    # and bulk queries filtering by account and product(s)
    add_index :license_assignments,
              [:account_id, :product_id],
              name: "index_license_assignments_on_account_and_product"

    # Speeds up listing users for an account ordered by name
    add_index :users,
              [:account_id, :name],
              name: "index_users_on_account_id_and_name"
  end
end


