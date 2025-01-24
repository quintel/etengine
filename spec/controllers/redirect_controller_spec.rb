# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RedirectController, type: :controller do
  let(:valid_page) { "identity/profile" } # Matches the :page param in the route
  let(:idp_url) { Settings.idp_url }
  let(:destination_url) { "#{idp_url}/#{valid_page}" }

  describe "GET #set_cookie_and_redirect" do
    context "when :page param is provided" do
      it "sets the :last_visited_page cookie to root_path and redirects to the constructed destination" do
        get :set_cookie_and_redirect, params: { page: valid_page }

        expect(cookies[:last_visited_page]).to eq root_path
        expect(response).to redirect_to(destination_url)
      end
    end

    context "when :page param is nil" do
      it "does not allow the route to be generated" do
        expect {
          get :set_cookie_and_redirect, params: { page: nil }
        }.to raise_error(ActionController::UrlGenerationError)
      end
    end

    context "when :page param is missing" do
      it "does not allow the route to be generated" do
        expect {
          get :set_cookie_and_redirect
        }.to raise_error(ActionController::UrlGenerationError)
      end
    end
  end
end
