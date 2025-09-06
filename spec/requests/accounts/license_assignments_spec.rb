# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Accounts::LicenseAssignmentsController', type: :request do
  let!(:account) { create(:account) }
  let!(:first_user) { create(:user, account: account) }
  let!(:second_user) { create(:user, account: account) }
  let!(:first_product) { create(:product) }
  let!(:second_product) { create(:product) }

  describe 'GET /accounts/:account_id/license_assignments' do
    it 'returns success and renders the list' do
      create(:subscription, account: account, product: first_product, number_of_licenses: 1)
      create(:license_assignment, account: account, user: first_user, product: first_product)

      get account_license_assignments_path(account)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(first_user.name)
      expect(response.body).to include(first_product.name)
    end
  end

  describe 'POST /accounts/:account_id/license_assignments (assign)' do
    context 'when capacity is sufficient' do
      before do
        create(:subscription, account: account, product: first_product, number_of_licenses: 2)
      end

      it 'assigns licenses and redirects with notice' do
        post account_license_assignments_path(account), params: {
          product_ids: [first_product.id],
          user_ids: [first_user.id, second_user.id]
        }

        expect(response).to redirect_to(account_path(account))
        follow_redirect!
        expect(response.body).to include('Assigned 2 license(s).')
        expect(LicenseAssignment.where(account: account, product: first_product).count).to eq(2)
      end
    end

    context 'when capacity is insufficient for some users' do
      before do
        create(:subscription, account: account, product: first_product, number_of_licenses: 1)
      end

      it 'assigns up to capacity and shows alert with capacity message' do
        post account_license_assignments_path(account), params: {
          product_ids: [first_product.id],
          user_ids: [first_user.id, second_user.id]
        }

        expect(response).to redirect_to(account_path(account))
        follow_redirect!
        expect(response.body).to include('Assigned 1 license(s).')
        expect(response.body).to include('insufficient capacity (1 remaining)')
        expect(LicenseAssignment.where(account: account, product: first_product).count).to eq(1)
      end
    end

    context 'when all selected users already have a license' do
      before do
        create(:subscription, account: account, product: first_product, number_of_licenses: 5)
        create(:license_assignment, account: account, user: first_user, product: first_product)
        create(:license_assignment, account: account, user: second_user, product: first_product)
      end

      it 'does not assign any license and shows notice with no assignment' do
        post account_license_assignments_path(account), params: {
          product_ids: [first_product.id],
          user_ids: [first_user.id, second_user.id]
        }

        expect(response).to redirect_to(account_path(account))
        follow_redirect!
        expect(response.body).to include('No licenses assigned.')
        expect(LicenseAssignment.where(account: account, product: first_product).count).to eq(2)
      end
    end
  end

  describe 'POST /accounts/:account_id/license_assignments/unassign' do
    before do
      create(:subscription, account: account, product: first_product, number_of_licenses: 5)
      create(:subscription, account: account, product: second_product, number_of_licenses: 5)
      create(:license_assignment, account: account, user: first_user, product: first_product)
      create(:license_assignment, account: account, user: second_user, product: first_product)
      create(:license_assignment, account: account, user: first_user, product: second_product)
    end

    it 'bulk unassigns selected product and users and redirects with notice' do
      expect {
        post unassign_account_license_assignments_path(account), params: {
          product_ids: [first_product.id],
          user_ids: [first_user.id, second_user.id]
        }
        expect(response).to redirect_to(account_path(account))
        follow_redirect!
        expect(response.body).to include('Unassigned 2 license(s).')
      }.to change(LicenseAssignment, :count).by(-2)

      # Ensure other product assignment remains
      expect(LicenseAssignment.exists?(account: account, product: second_product, user: first_user)).to be true
    end
  end
end


