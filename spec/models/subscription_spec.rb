# frozen_string_literal: true

RSpec.describe Subscription, type: :model do
  let(:account) { create(:account) }
  let(:product) { create(:product) }
  subject { build(:subscription, account: account, product: product) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:product) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:issued_at) }
    it { is_expected.to validate_presence_of(:expires_at) }
    it { is_expected.to validate_numericality_of(:number_of_licenses).only_integer.is_greater_than(0) }

    it 'is invalid when expires_at is before or equal to issued_at' do
      issued_at = Time.zone.parse('2025-01-01 00:00:00 UTC')
      subscription = build(:subscription, account: account, product: product, issued_at: issued_at, expires_at: issued_at)
      expect(subscription).not_to be_valid
      expect(subscription.errors[:expires_at]).to include('must be after issued_at')
    end

    it 'validates product uniqueness scoped to account' do
      # Existing subscription for the same account/product
      create(:subscription, account: account, product: product)
      duplicate = build(:subscription, account: account, product: product)
      expect(duplicate).not_to be_valid
      # We expect a uniqueness error either on product or base depending on validation configuration
      expect(duplicate.errors[:product] + duplicate.errors[:product_id] + duplicate.errors[:base]).not_to be_empty
    end
  end

  describe 'callbacks' do
    it 'prevents destroying when license assignments exist for its account/product' do
      subscription = create(:subscription, account: account, product: product)
      user = create(:user, account: account)
      create(:license_assignment, account: account, product: product, user: user)

      expect(subscription.destroy).to be false
      expect(subscription.errors[:base]).to include('Cannot delete subscription while licenses are assigned')
      expect(Subscription.exists?(subscription.id)).to be true
    end
  end
end
