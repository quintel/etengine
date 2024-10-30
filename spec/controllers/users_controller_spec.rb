require 'spec_helper'

describe UsersController do
  let(:admin) { FactoryBot.create(:admin) }

  describe 'GET index' do
    it 'redirects non admins' do
      get :index
      expect(response).to be_redirect
    end

    it 'works for admins' do
      # sign_in(admin)
      get :index
      expect(response).to be_successful
      expect(response).to render_template(:index)
    end
  end

  describe 'GET edit' do
    it 'redirects guests' do
      get :edit, params: { id: admin.id }
      expect(response).to be_redirect
    end

    it 'works for admins' do
      # sign_in(admin)
      get :edit, params: { id: admin.id }
      expect(response).to be_successful
      expect(assigns(:user)).to eq(admin)
      expect(response).to render_template(:edit)
    end
  end

  describe 'POST resend_confirmation_email' do
    let(:admin) { create(:admin, :confirmed_at) }
    let(:unconfirmed_user) { create(:user) }
    let(:confirmed_user) { create(:user, :confirmed_at) }

    before do
      # sign_in admin
    end

    context 'when user is unconfirmed' do
      it 'resends the confirmation email' do
        expect do
          post(:resend_confirmation_email, params: { id: unconfirmed_user.id })
        end.to change {
                 ActionMailer::Base.deliveries.count
               }.by(2)   # 2 emails: confirmation and welcome.

        expect(response).to redirect_to(users_path)
        expect(flash[:notice]).to eq("Confirmation email resent to #{unconfirmed_user.email}.")
      end
    end

    context 'when user is already confirmed' do
      it 'does not resend the confirmation email' do
        expect do
          post(:resend_confirmation_email, params: { id: confirmed_user.id })
        end.not_to change { ActionMailer::Base.deliveries.count }

        expect(response).to redirect_to(users_path)
        expect(flash[:notice]).to eq('User is already confirmed.')
      end
    end

    context 'when user does not exist' do
      it 'redirects with an alert message' do
        expect do
          post(:resend_confirmation_email, params: { id: -1 })
        end
          .not_to(change { ActionMailer::Base.deliveries.count })

        expect(response).to redirect_to(users_path)
        expect(flash[:notice]).to eq('User does not exist.')
      end
    end
  end
end
