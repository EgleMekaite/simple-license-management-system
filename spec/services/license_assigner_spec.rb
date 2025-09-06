# frozen_string_literal: true

describe LicenseAssigner, type: :service do
  describe '#call' do
    subject(:license_assigner) { described_class.new(account.id, product_ids, user_ids) }

    let!(:account) { create(:account) }
    let!(:product_1) { create(:product) }
    let!(:product_2) { create(:product) }
    let!(:user_1) { create(:user, account: account) }
    let!(:user_2) { create(:user, account: account) }
    let!(:subscription_product_1) do
      create(:subscription,
             product: product_1,
             account: account,
             number_of_licenses: 2)
    end
    let!(:subscription_product_2) do
      create(:subscription,
             product: product_2,
             account: account,
             number_of_licenses: 2)
    end
    let(:product_ids) { [product_1.id, product_2.id] }
    let(:user_ids) { [user_1.id, user_2.id] }

    describe 'when product_ids are empty' do
      let(:product_ids) { [] }
      let(:expected_result) { [0, ["No products selected."]] }

      it 'returns 0 count and respoective message' do
        expect(license_assigner.call).to eq expected_result
      end
    end

    describe 'when user_ids are empty' do
      let(:user_ids) { [] }
      let(:expected_result) { [0, ["No users selected."]] }

      it 'returns 0 count and respoective message' do
        expect(license_assigner.call).to eq expected_result
      end
    end

    describe 'assigns licenses when capacity is sufficient' do
      let(:product_ids) { [product_1.id] }
      let(:user_ids) { [user_1.id, user_2.id] }

      it 'creates assignments for all users' do
        expect {
          total_assigned, messages = license_assigner.call
          expect(total_assigned).to eq 2
          expect(messages).to be_empty
        }.to change(LicenseAssignment, :count).by(2)
        expect(LicenseAssignment.exists?(account: account, product: product_1, user: user_1)).to be true
        expect(LicenseAssignment.exists?(account: account, product: product_1, user: user_2)).to be true
      end
    end

    describe 'assigns across multiple products with capacity limits' do
      let(:product_ids) { [product_1.id, product_2.id] }
      let(:user_ids) { [user_1.id, user_2.id] }

      before do
        subscription_product_1.update!(number_of_licenses: 2)
        subscription_product_2.update!(number_of_licenses: 1)
      end

      it 'assigns up to capacity per product and reports insufficient capacity' do
        expect {
          total_assigned, messages = license_assigner.call
          expect(total_assigned).to eq 3
          expect(messages.join(' ')).to include('insufficient capacity (1 remaining)')
        }.to change(LicenseAssignment, :count).by(3)

        # Product 1 should have both users assigned
        expect(LicenseAssignment.exists?(account: account, product: product_1, user: user_1)).to be true
        expect(LicenseAssignment.exists?(account: account, product: product_1, user: user_2)).to be true

        # Product 2 should have only one user assigned (any one)
        assigned_users_for_product_2 = LicenseAssignment.where(account: account, product: product_2).pluck(:user_id)
        expect(assigned_users_for_product_2.size).to eq 1
        expect(assigned_users_for_product_2).to all(be_in([user_1.id, user_2.id]))
      end
    end

    describe 'does not assign duplicate licenses for the same user and product' do
      let(:product_ids) { [product_1.id] }
      let(:user_ids) { [user_1.id, user_2.id] }

      before do
        create(:license_assignment, account: account, product: product_1, user: user_1)
        subscription_product_1.update!(number_of_licenses: 2)
      end

      it 'assigns only to users without an existing license and does not report capacity issue' do
        expect {
          total_assigned, messages = license_assigner.call
          expect(total_assigned).to eq 1
          expect(messages).to be_empty
        }.to change(LicenseAssignment, :count).by(1)

        # User 1 already had a license; only User 2 should be newly assigned
        expect(LicenseAssignment.exists?(account: account, product: product_1, user: user_1)).to be true
        expect(LicenseAssignment.exists?(account: account, product: product_1, user: user_2)).to be true
      end
    end

    describe 'limits assignments when capacity is insufficient' do
      let(:product_ids) { [product_1.id] }
      let(:user_ids) { [user_1.id, user_2.id] }

      before do
        subscription_product_1.update!(number_of_licenses: 1)
      end

      it 'assigns only up to remaining capacity and reports insufficient capacity' do
        expect {
          total_assigned, messages = license_assigner.call
          expect(total_assigned).to eq 1
          expect(messages.join(' ')).to include('insufficient capacity (1 remaining)')
        }.to change(LicenseAssignment, :count).by(1)
      end
    end

    describe 'reports when there is no subscription for a selected product' do
      let!(:unsubscribed_product) { create(:product) }
      let(:product_ids) { [unsubscribed_product.id] }
      let(:user_ids) { [user_1.id] }

      it 'does not create assignments and reports missing subscription' do
        expect {
          total_assigned, messages = license_assigner.call
          expect(total_assigned).to eq 0
          expect(messages.join(' ')).to include("No subscription for product #{unsubscribed_product.name}.")
        }.not_to change(LicenseAssignment, :count)
      end
    end
  end
end
