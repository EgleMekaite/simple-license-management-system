# frozen_string_literal: true

RSpec.describe "Products", type: :request do
  describe "GET /products" do
    it "renders the index successfully" do
      get products_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Products")
    end
  end

  describe "GET /products/new" do
    it "renders the form for creating a new product" do
      get new_product_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Product")
    end
  end

  describe "POST /products" do
    context "with valid params" do
      let(:expected_product_name) { "Product X" }
      let(:expected_product_description) { "Desc" }

      it "creates a product and redirects to product detail page" do
        expect {
          post products_path, params: { product: { name: expected_product_name, description: expected_product_description } }
        }.to change(Product, :count).by(1)

        product = Product.order(:created_at).last
        expect(response).to redirect_to(product_path(product))
        follow_redirect!
        expect(response.body).to include(expected_product_name)
      end
    end

    context "with invalid params" do
      it "does not create a product and renders the form with errors" do
        expect {
          post products_path, params: { product: { name: "", description: "" } }
        }.not_to change(Product, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("error")
      end
    end

    context "with missing required params" do
      it "returns 422 and shows missing param error" do
        expect {
          post products_path, params: { product: { description: "foo" } }
        }.not_to change(Product, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("is required").or include("error")
      end
    end
  end
end


