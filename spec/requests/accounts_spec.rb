# frozen_string_literal: true

RSpec.describe "Accounts", type: :request do
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


