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
  end
end
