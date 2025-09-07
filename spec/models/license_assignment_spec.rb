# frozen_string_literal: true

RSpec.describe LicenseAssignment, type: :model do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:product) { create(:product) }
  subject { build(:license_assignment, account: account, user: user, product: product) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:product) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:account) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:product) }

    it 'does not allow duplicate assignment for same account, user, and product' do
      create(:license_assignment, account: account, user: user, product: product)
      duplicate = build(:license_assignment, account: account, user: user, product: product)
      expect(duplicate).not_to be_valid
    end
  end

  describe 'scopes' do
    let!(:other_account) { create(:account) }
    let!(:first_product) { create(:product) }
    let!(:second_product) { create(:product) }
    let!(:first_user) { create(:user, account: account) }
    let!(:second_user) { create(:user, account: account) }

    let!(:first_license_assignment) { create(:license_assignment, account: account, product: first_product, user: first_user) }
    let!(:second_license_assignment) { create(:license_assignment, account: account, product: second_product, user: second_user) }
    let!(:other_account_license_assignment) { create(:license_assignment, account: other_account, product: first_product, user: create(:user, account: other_account)) }

    describe '.for_account' do
      it 'returns only assignments for the given account' do
        expect(LicenseAssignment.for_account(account.id)).to contain_exactly(first_license_assignment, second_license_assignment)
      end
    end

    describe '.for_products' do
      it 'returns assignments matching the given product ids' do
        expect(LicenseAssignment.for_products([first_product.id])).to include(first_license_assignment)
        expect(LicenseAssignment.for_products([first_product.id])).not_to include(second_license_assignment)
      end
    end
  end
end
