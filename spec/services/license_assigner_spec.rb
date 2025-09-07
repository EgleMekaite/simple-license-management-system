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

      it 'returns 0 count and respective message' do
        expect {
          total_assigned, messages = license_assigner.call
          expect(total_assigned).to eq 0
          expect(messages).to eq ["No products selected."]
        }.not_to change(LicenseAssignment, :count)
      end
    end

    describe 'when user_ids are empty' do
      let(:user_ids) { [] }
      it 'returns 0 count and respective message' do
        expect {
          total_assigned, messages = license_assigner.call
          expect(total_assigned).to eq 0
          expect(messages).to eq ["No users selected."]
        }.not_to change(LicenseAssignment, :count)
      end
    end

    describe 'when there is no subscription for a selected product' do
      let!(:unsubscribed_product) { create(:product) }
      let(:product_ids) { [unsubscribed_product.id] }
      let(:user_ids) { [user_1.id] }

      it 'does not assign the license and reports missing subscription' do
        expect {
          total_assigned, messages = license_assigner.call
          expect(total_assigned).to eq 0
          expect(messages.join(' ')).to include("No subscription for product #{unsubscribed_product.name}.")
        }.not_to change(LicenseAssignment, :count)
      end
    end

    describe 'when there are sufficient licenses' do
      describe 'when assigning one product to one user' do
        let(:product_ids) { [product_1.id] }
        let(:user_ids) { [user_1.id] }

        it 'assigns the license to the selected user' do
          expect {
            total_assigned, messages = license_assigner.call
            expect(total_assigned).to eq 1
            expect(messages).to be_empty
          }.to change(LicenseAssignment, :count).by(1)
          expect(LicenseAssignment.exists?(account: account, product: product_1, user: user_1)).to be true
        end
      end

      describe 'when assigning one product to multiple users' do
        let(:product_ids) { [product_1.id] }
        let(:user_ids) { [user_1.id, user_2.id] }

        it 'assigns licenses to all selected users' do
          expect {
            total_assigned, messages = license_assigner.call
            expect(total_assigned).to eq 2
            expect(messages).to be_empty
          }.to change(LicenseAssignment, :count).by(2)
          expect(LicenseAssignment.exists?(account: account, product: product_1, user: user_1)).to be true
          expect(LicenseAssignment.exists?(account: account, product: product_1, user: user_2)).to be true
        end
      end

      describe 'when assigning multiple products to multiple users' do
        let(:product_ids) { [product_1.id, product_2.id] }
        let(:user_ids) { [user_1.id, user_2.id] }

        it 'assigns licenses to all selected users' do
          expect {
            total_assigned, messages = license_assigner.call
            expect(total_assigned).to eq 4
            expect(messages).to be_empty
          }.to change(LicenseAssignment, :count).by(4)
          expect(LicenseAssignment.exists?(account: account, product: product_1, user: user_1)).to be true
          expect(LicenseAssignment.exists?(account: account, product: product_1, user: user_2)).to be true
          expect(LicenseAssignment.exists?(account: account, product: product_2, user: user_1)).to be true
          expect(LicenseAssignment.exists?(account: account, product: product_2, user: user_2)).to be true
        end
      end

      describe 'when assigning one product to multiple users but some users already have a license' do
        let(:product_ids) { [product_1.id] }
        let(:user_ids) { [user_1.id, user_2.id] }

        before do
          create(:license_assignment, account: account, product: product_1, user: user_1)
        end

        it 'assigns only to users without an existing license and reports duplicates' do
          expect {
            total_assigned, messages = license_assigner.call
            expect(total_assigned).to eq 1
            expect(messages.join(' ')).to include("[#{product_1.name}] 1 user(s) already licensed.")
          }.to change(LicenseAssignment, :count).by(1)
          expect(LicenseAssignment.exists?(account: account, product: product_1, user: user_2)).to be true
        end
      end
    end

    describe 'when there are insufficient licenses' do
      describe 'when for some products there are sufficient licenses' do
        let(:product_ids) { [product_1.id, product_2.id] }
        let(:user_ids) { [user_1.id, user_2.id] }

        before do
          subscription_product_2.update!(number_of_licenses: 1)
        end

        it 'assigns the licenses to all selected users where they are sufficient, and reports capacity issue for others' do
          expect {
            total_assigned, messages = license_assigner.call
            expect(total_assigned).to eq 2
            expect(messages.join(' ')).to include("Cannot assign to all selected users: #{product_2.name} has 1 license(s) remaining.")
          }.to change(LicenseAssignment, :count).by(2)

          expect(LicenseAssignment.exists?(account: account, product: product_1, user: user_1)).to be true
          expect(LicenseAssignment.exists?(account: account, product: product_1, user: user_2)).to be true

          assigned_users_for_product_2 = LicenseAssignment.where(account: account, product: product_2).pluck(:user_id)
          expect(assigned_users_for_product_2.size).to eq 0
        end
      end

      describe 'when there are no sufficient licenses for any product' do
        let(:product_ids) { [product_1.id, product_2.id] }
        let(:user_3) { create(:user, account: account) }
        let(:user_4) { create(:user, account: account) }
        let(:user_ids) { [user_3.id, user_4.id] }

        before do
          subscription_product_1.update!(number_of_licenses: 1)
          subscription_product_2.update!(number_of_licenses: 1)
          create(:license_assignment, account: account, product: product_1, user: user_1)
          create(:license_assignment, account: account, product: product_2, user: user_2)
        end

        it 'does not assign any licenses and reports capacity issue for all products' do
          expect {
            total_assigned, messages = license_assigner.call
            expect(total_assigned).to eq 0
            expect(messages.join(' ')).to include("Cannot assign to all selected users: #{product_1.name} has 0 license(s) remaining.")
            expect(messages.join(' ')).to include("Cannot assign to all selected users: #{product_2.name} has 0 license(s) remaining.")
          }.not_to change(LicenseAssignment, :count)
        end
      end

      describe 'when capacity is exceeded and some selected users are already licensed' do
        let(:product_ids) { [product_1.id] }
        let(:user_ids) { [user_1.id, user_2.id] }

        before do
          subscription_product_1.update!(number_of_licenses: 1)
          create(:license_assignment, account: account, product: product_1, user: user_1)
        end

        it 'assigns nothing and reports both capacity and duplicates messages' do
          expect {
            total_assigned, messages = license_assigner.call
            expect(total_assigned).to eq 0
            expect(messages.join(' ')).to include("Cannot assign to all selected users: #{product_1.name} has 0 license(s) remaining.")
            expect(messages.join(' ')).to include("[#{product_1.name}] 1 user(s) already licensed.")
          }.not_to change(LicenseAssignment, :count)
        end
      end
    end

    describe 'when for some user/product creating LicenseAssignment fails' do
      let(:product_ids) { [product_1.id] }
      let(:user_ids) { [user_1.id] }

      it 'continues and collects error messages' do
        invalid = LicenseAssignment.new
        invalid.errors.add(:base, 'Some validation error')
        allow(LicenseAssignment).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(invalid))
  
        total_assigned, messages = license_assigner.call
  
        expect(total_assigned).to eq(0)
        expect(messages.join(' ')).to include('Some validation error')
      end
    end
  end
end
