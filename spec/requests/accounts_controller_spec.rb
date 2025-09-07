# frozen_string_literal: true

RSpec.describe 'AccountsController', type: :request do
  describe 'GET /accounts' do
    it 'renders list of accounts' do
      create(:account, name: 'Acme')
      create(:account, name: 'Beta Corp')

      get accounts_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Acme')
      expect(response.body).to include('Beta Corp')
    end
  end

  describe 'GET /accounts/:id' do
    let!(:account) { create(:account, name: 'Acme') }
    let!(:user_1) { create(:user, account: account, name: 'Alice') }
    let!(:user_2) { create(:user, account: account, name: 'Bob') }
    let!(:product_a) { create(:product, name: 'Product A') }
    let!(:product_b) { create(:product, name: 'Product B') }
    let!(:subscription_a) { create(:subscription, account: account, product: product_a, number_of_licenses: 3) }
    let!(:subscription_b) { create(:subscription, account: account, product: product_b, number_of_licenses: 1) }

    before do
      # Use one license for product A so remaining becomes 2/3
      create(:license_assignment, account: account, product: product_a, user: user_1)
    end

    it 'renders account show with precomputed remaining/total counts and user list' do
      get account_path(account)

      expect(response).to have_http_status(:ok)
      # Remaining/total displayed for each subscription
      expect(response.body).to include('Product A (2/3)')
      expect(response.body).to include('Product B (1/1)')
      # Users list is present
      expect(response.body).to include('Alice')
      expect(response.body).to include('Bob')
    end
  end

  describe 'GET /accounts/new' do
    it 'renders the new account form' do
      get new_account_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('New Account')
    end
  end

  describe 'POST /accounts' do
    it 'creates an account and redirects to show with notice' do
      post accounts_path, params: { account: { name: 'NewCo' } }

      expect(response).to redirect_to(account_path(Account.last))
      follow_redirect!
      expect(response.body).to include('Account was successfully created.')
      expect(response.body).to include('NewCo')
    end
  end
end

# frozen_string_literal: true

RSpec.describe "AccountsController", type: :request do
  describe "GET /accounts" do
    it "renders the index successfully" do
      get accounts_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Accounts")
    end
  end

  describe "GET /accounts/new" do
    it "renders the form for creating a new account" do
      get new_account_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Account")
    end
  end

  describe "POST /accounts" do
    context "with valid params" do
      let(:expected_account_name) { "Account 1" }

      it "creates an account and redirects to account detail page" do
        expect {
          post accounts_path, params: { account: { name: expected_account_name } }
        }.to change(Account, :count).by(1)

        account = Account.order(:created_at).last
        expect(response).to redirect_to(account_path(account))
        follow_redirect!
        expect(response.body).to include(expected_account_name)
      end
    end

    context "with invalid params" do
      it "does not create an account and renders the form with errors" do
        expect {
          post accounts_path, params: { account: { name: "" } }
        }.not_to change(Account, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("error")
      end
    end

    context "with missing required params" do
      it "returns 422 and shows missing param error" do
        expect {
          post accounts_path, params: { account: {} }
        }.not_to change(Account, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("is required").or include("error")
      end
    end
  end
end


