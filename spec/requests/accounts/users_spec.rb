# frozen_string_literal: true

RSpec.describe "Users (nested under accounts)", type: :request do
  let!(:account) { create(:account) }

  describe "GET /accounts/:account_id/users" do
    it "renders the users list for the account" do
      get account_users_path(account)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(account.name)
    end
  end

  describe "GET /accounts/:account_id/users/new" do
    it "renders the form for creating a new user" do
      get new_account_user_path(account)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New User")
    end
  end

  describe "POST /accounts/:account_id/users" do
    context "with valid params" do
      let(:expected_user_name) { "Jane" }
      let(:expected_user_email) { "jane@example.com" }

      it "creates a user and redirects to the account's users index" do
        expect {
          post account_users_path(account), params: { user: { name: expected_user_name, email: expected_user_email } }
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(account_users_path(account))
        follow_redirect!
        expect(response.body).to include("Users for")
        expect(response.body).to include(expected_user_name)
        expect(response.body).to include(expected_user_email)

        created_user = User.find_by(email: expected_user_email)
        expect(created_user).to be_present
        expect(created_user.account_id).to eq(account.id)
        expect(account.users.exists?(created_user.id)).to be(true)
      end
    end

    context "with duplicate email" do
      let(:taken_user_email) { "taken@example.com" }

      it "does not create the user and renders the form with errors" do
        create(:user, account: account, email: taken_user_email)
        expect {
          post account_users_path(account), params: { user: { name: "Dup Name", email: taken_user_email } }
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("error")
      end
    end

    context "with missing required params" do
      it "returns 422 and shows missing param error" do
        expect {
          post account_users_path(account), params: { user: { name: "" } }
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("is required").or include("error")
      end
    end
  end
end
