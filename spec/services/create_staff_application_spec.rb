# frozen_string_literal: true

RSpec.describe CreateStaffApplication do
  let(:user) { create(:admin) }

  let(:app_config) do
    ETEngine::StaffApplications::AppConfig.new(
      key: 'my_app',
      name: 'My application',
      uri: 'http://localhost:3000',
      scopes: 'email',
      redirect_path: '/auth',
      config_path: 'conf.yml',
      config_content: ''
    )
  end

  let(:app) { described_class.call(user, app_config).value! }

  context 'when the user does not have a matching application' do
    it 'creates a new application' do
      expect { app }
        .to change { user.staff_applications.count }
        .from(0)
        .to(1)
    end

    it 'creates OAuth applications for the user' do
      expect { app }
        .to change { user.oauth_applications.count }
        .from(0)
        .to(1)
    end

    it 'sets the default URI' do
      expect(app.application.uri).to eq('http://localhost:3000')
    end

    it 'sets the default redirect URI' do
      expect(app.application.redirect_uri).to eq('http://localhost:3000/auth')
    end

    context 'when given a custom URI' do
      let(:app) { described_class.call(user, app_config, uri: 'http://myapp.test').value! }

      it 'sets a custom URI' do
        expect(app.application.uri).to eq('http://myapp.test')
      end

      it 'sets a custom redirect URI' do
        expect(app.application.redirect_uri).to eq('http://myapp.test/auth')
      end
    end
  end

  context 'when the user already has the staff application' do
    before do
      described_class.call(user, app_config)
    end

    it 'does not create a new application' do
      expect { app }.not_to change(user.staff_applications, :count)
    end

    context 'when the application uri is different' do
      it 'does not update the application URI' do
        new_config = ETEngine::StaffApplications::AppConfig.new(
          app_config.to_h.merge(url: 'http://wwww.example.org')
        )

        oauth_app = user.staff_applications.find_by!(name: app_config.key).application
        oauth_app.update!(uri: 'http://other-host:3001')

        expect { described_class.call(user, new_config) }
          .not_to change { oauth_app.reload.uri }
          .from('http://other-host:3001')
      end
    end

    context 'when the application redirect_uri is different' do
      it 'updates the path of the existing URI' do
        new_config = ETEngine::StaffApplications::AppConfig.new(
          app_config.to_h.merge(redirect_path: '/auth/callback')
        )

        oauth_app = user.staff_applications.find_by!(name: app_config.key).application

        oauth_app.update!(
          uri: 'http://other-host:3001',
          redirect_uri: 'http://other-host:3001/auth'
        )

        expect { described_class.call(user, new_config) }
          .to change { oauth_app.reload.redirect_uri }
          .from('http://other-host:3001/auth')
          .to('http://other-host:3001/auth/callback')
      end
    end

    context 'when the application scope is different' do
      it 'updates the scopes of the existing application' do
        new_config = ETEngine::StaffApplications::AppConfig.new(
          app_config.to_h.merge(scopes: 'profile')
        )

        oauth_app = user.staff_applications.find_by!(name: app_config.key).application
        oauth_app.update!(scopes: 'openid')

        expect { described_class.call(user, new_config) }
          .to change { oauth_app.reload.scopes.to_s }
          .from('openid')
          .to('profile')
      end
    end
  end
end
