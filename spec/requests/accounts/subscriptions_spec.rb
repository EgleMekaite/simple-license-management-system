# frozen_string_literal: true

RSpec.describe "Subscriptions (nested under accounts)", type: :request do
  let!(:account) { create(:account) }
  let!(:product) { create(:product) }

  describe "GET /accounts/:account_id/subscriptions" do
    it "renders the subscriptions list for the account" do
      get account_subscriptions_path(account)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(account.name)
    end
  end

  describe "GET /accounts/:account_id/subscriptions/new" do
    it "renders the new subscription form" do
      get new_account_subscription_path(account)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Subscription")
    end
  end

  describe "POST /accounts/:account_id/subscriptions" do
    context "with valid params" do
      it "creates a subscription and redirects to the subscriptions index" do
        valid_params = {
          subscription: {
            product_id: product.id,
            number_of_licenses: 2,
            expires_at: 1.day.from_now
          }
        }

        expect {
          post account_subscriptions_path(account), params: valid_params
        }.to change(Subscription, :count).by(1)

        expect(response).to redirect_to(account_subscriptions_path(account))
        follow_redirect!
        expect(response.body).to include("Subscriptions for")

        created_subscription = Subscription.order(:created_at).last
        expect(created_subscription.account_id).to eq(account.id)
        expect(created_subscription.product_id).to eq(product.id)
        expect(account.subscriptions.exists?(created_subscription.id)).to be(true)
      end
    end

    context "with invalid params" do
      it "does not create and renders new with errors" do
        invalid_params = {
          subscription: {
            product_id: product.id,
            number_of_licenses: 0,
            expires_at: 1.day.from_now
          }
        }

        expect {
          post account_subscriptions_path(account), params: invalid_params
        }.not_to change(Subscription, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("error").or include("must be greater than 0")
      end
    end

    context "with missing required params" do
      it "returns 422 and shows missing param error" do
        expect {
          post account_subscriptions_path(account), params: { subscription: { } }
        }.not_to change(Subscription, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("is required").or include("error")
      end
    end
  end
end
