# frozen_string_literal: true

RSpec.describe Product, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:subscriptions) }
    it { is_expected.to have_many(:license_assignments) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
  end
end
