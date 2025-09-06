# frozen_string_literal: true

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:license_assignments) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end
end
