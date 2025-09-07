# frozen_string_literal: true

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:license_assignments).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end

  describe '.ordered_by_name' do
    let!(:account) { create(:account) }
    let!(:user_alice) { create(:user, account: account, name: 'Alice') }
    let!(:user_bob) { create(:user, account: account, name: 'Bob') }
    let!(:user_charlie) { create(:user, account: account, name: 'Charlie') }

    it 'orders by name ascending' do
      expect(User.ordered_by_name.pluck(:id)).to eq([user_alice.id, user_bob.id, user_charlie.id])
    end
  end
end
