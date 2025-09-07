# frozen_string_literal: true

RSpec.describe 'Accounts::LicenseAssignmentsController', type: :request do
  let!(:account) { create(:account) }
  let!(:user_1) { create(:user, account: account) }
  let!(:user_2) { create(:user, account: account) }
  let!(:product_1) { create(:product) }
  let!(:product_2) { create(:product) }

  describe 'GET /accounts/:account_id/license_assignments' do
    it 'returns success and renders the list' do
      create(:subscription, account: account, product: product_1, number_of_licenses: 1)
      create(:license_assignment, account: account, user: user_1, product: product_1)

      get account_license_assignments_path(account)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user_1.name)
      expect(response.body).to include(product_1.name)
    end
  end

  describe 'POST /accounts/:account_id/license_assignments (assign)' do
    context 'when capacity is sufficient' do
      before do
        create(:subscription, account: account, product: product_1, number_of_licenses: 2)
      end

      it 'assigns licenses and redirects with notice' do
        post account_license_assignments_path(account), params: {
          product_ids: [product_1.id],
          user_ids: [user_1.id, user_2.id]
        }

        expect(response).to redirect_to(account_path(account))
        follow_redirect!
        expect(response.body).to include('Assigned 2 license(s).')
        expect(LicenseAssignment.where(account: account, product: product_1).count).to eq(2)
      end
    end

    context 'when capacity is insufficient for some users' do
      before do
        create(:subscription, account: account, product: product_1, number_of_licenses: 1)
      end

      it 'does not assign partially and shows alert with capacity and duplicates messages when applicable' do
        post account_license_assignments_path(account), params: {
          product_ids: [product_1.id],
          user_ids: [user_1.id, user_2.id]
        }

        expect(response).to redirect_to(account_path(account))
        follow_redirect!
        expect(response.body).to include('No licenses assigned.')
        expect(response.body).to include("Cannot assign to all selected users: #{product_1.name} has 1 license(s) remaining.")
        # When capacity blocks assignment, duplicates may still be reported
        # if any selected users were already licensed for the product
        # (setup here doesn't pre-license anyone, so we don't expect it by default)
        expect(LicenseAssignment.where(account: account, product: product_1).count).to eq(0)
      end
    end

    context 'when all selected users already have a license' do
      before do
        create(:subscription, account: account, product: product_1, number_of_licenses: 5)
        create(:license_assignment, account: account, user: user_1, product: product_1)
        create(:license_assignment, account: account, user: user_2, product: product_1)
      end

      it 'does not assign any license and shows notice with no assignment, reporting duplicates' do
        post account_license_assignments_path(account), params: {
          product_ids: [product_1.id],
          user_ids: [user_1.id, user_2.id]
        }

        expect(response).to redirect_to(account_path(account))
        follow_redirect!
        expect(response.body).to include('No licenses assigned.')
        expect(response.body).to include("[#{product_1.name}] 2 user(s) already licensed.")
        expect(LicenseAssignment.where(account: account, product: product_1).count).to eq(2)
      end
    end

    context 'when product_ids or user_ids are missing' do
      before do
        create(:subscription, account: account, product: product_1, number_of_licenses: 2)
      end

      it 'redirects with service message when product_ids is missing' do
        post account_license_assignments_path(account), params: {
          user_ids: [user_1.id]
        }

        expect(response).to redirect_to(account_path(account))
        follow_redirect!
        expect(response.body).to include('No products selected.')
      end

      it 'redirects with service message when user_ids is missing' do
        post account_license_assignments_path(account), params: {
          product_ids: [product_1.id]
        }

        expect(response).to redirect_to(account_path(account))
        follow_redirect!
        expect(response.body).to include('No users selected.')
      end
    end
  end

  describe 'POST /accounts/:account_id/license_assignments/unassign' do
    before do
      create(:subscription, account: account, product: product_1, number_of_licenses: 5)
      create(:subscription, account: account, product: product_2, number_of_licenses: 5)
      create(:license_assignment, account: account, user: user_1, product: product_1)
      create(:license_assignment, account: account, user: user_2, product: product_1)
      create(:license_assignment, account: account, user: user_1, product: product_2)
    end

    it 'bulk unassigns selected product and users and redirects with notice' do
      expect {
        post unassign_account_license_assignments_path(account), params: {
          product_ids: [product_1.id],
          user_ids: [user_1.id, user_2.id]
        }
        expect(response).to redirect_to(account_path(account))
        follow_redirect!
        expect(response.body).to include('Unassigned 2 license(s).')
      }.to change(LicenseAssignment, :count).by(-2)

      expect(LicenseAssignment.exists?(account: account, product: product_2, user: user_1)).to be true
    end

    it 'redirects with service message when params are missing' do
      post unassign_account_license_assignments_path(account), params: {
        product_ids: []
      }
      expect(response).to redirect_to(account_path(account))
      follow_redirect!
      expect(response.body).to include('Unassigned 0 license(s).')
    end
  end
end


