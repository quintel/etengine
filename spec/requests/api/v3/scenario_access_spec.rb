# frozen_string_literal: true

require 'spec_helper'

describe 'Scenario access granted by MyETM with API v3', :etsource_fixture do
  let(:creator) { create(:user) }
  let(:user) { create(:user) }

  def session(private: false, bound: false, creator_id: nil)
    create(:scenario, private:, bound:, creator_id:)
  end

  def show(scenario, actor = nil, access = nil)
    get(
      "/api/v3/scenarios/#{scenario.id}",
      headers: access_token_header(actor, :read, scenario_access: access)
    )
  end

  def update(scenario, actor = nil, access = nil, params = { keep_compatible: true })
    put(
      "/api/v3/scenarios/#{scenario.id}",
      params: { scenario: params },
      headers: access_token_header(actor, :write, scenario_access: access)
    )
  end

  def destroy(scenario, actor, access = nil)
    delete(
      "/api/v3/scenarios/#{scenario.id}",
      headers: access_token_header(actor, :delete, scenario_access: access)
    )
  end

  def interpolate(scenario, actor, access)
    post(
      "/api/v3/scenarios/#{scenario.id}/interpolate",
      params: { end_year: 2030 },
      headers: access_token_header(actor, :write, scenario_access: access)
    )
  end

  def create_from(scenario, actor, access)
    post(
      '/api/v3/scenarios',
      params: { scenario: { scenario_id: scenario.id } },
      headers: access_token_header(actor, :write, scenario_access: access)
    )
  end

  def created_scenario
    Scenario.find(response.parsed_body['id'])
  end

  def read(scenario) = { 'read' => [scenario.id] }

  def write(scenario) = { 'write' => [scenario.id] }

  context 'with grants only off' do
    let(:scenario) { create(:scenario, user: creator, private: true) }

    it 'ignores a read grant' do
      show(scenario, user, read(scenario))

      expect(response).to have_http_status(:not_found)
    end

    it 'ignores a write grant' do
      update(scenario, user, write(scenario))

      expect(response).to have_http_status(:not_found)
    end
  end

  context 'with grants only on' do
    before { Settings.scenario_access_grants_only = true }
    after { Settings.scenario_access_grants_only = false }

    describe 'a bound public Session' do
      let(:scenario) { session(bound: true) }

      it 'is readable by a guest' do
        show(scenario)

        expect(response).to have_http_status(:ok)
      end

      it 'refuses a write from a guest' do
        update(scenario)

        expect(response).to have_http_status(:forbidden)
      end

      it 'refuses a write from a user without a grant' do
        update(scenario, user)

        expect(response).to have_http_status(:forbidden)
      end

      it 'accepts a write with a write grant' do
        update(scenario, user, write(scenario))

        expect(response).to have_http_status(:ok)
      end
    end

    describe 'a bound private Session' do
      let(:scenario) { session(private: true, bound: true) }

      it 'refuses a user without a grant' do
        show(scenario, user)

        expect(response).to have_http_status(:not_found)
      end

      it 'is readable with a read grant' do
        show(scenario, user, read(scenario))

        expect(response).to have_http_status(:ok)
      end

      it 'refuses a write with a read grant' do
        update(scenario, user, read(scenario))

        expect(response).to have_http_status(:not_found)
      end

      it 'is readable with a write grant' do
        show(scenario, user, write(scenario))

        expect(response).to have_http_status(:ok)
      end

      it 'accepts a write with a write grant' do
        update(scenario, user, write(scenario))

        expect(response).to have_http_status(:ok)
      end

      it 'ignores a scenario_users role' do
        ScenarioUser.create!(scenario:, user:, role_id: User::ROLES.key(:scenario_owner))
        update(scenario, user)

        expect(response).to have_http_status(:not_found)
      end

      it 'is readable by an admin without a grant' do
        show(scenario, create(:user, admin: true))

        expect(response).to have_http_status(:ok)
      end

      it 'refuses a delete with a write grant' do
        destroy(scenario, user, write(scenario))

        expect(response).to have_http_status(:not_found)
      end

      it 'is deleted by an admin' do
        destroy(scenario, create(:user, admin: true))

        expect(Scenario.exists?(scenario.id)).to be(false)
      end

      it 'refuses a clone with a read grant' do
        interpolate(scenario, user, read(scenario))

        expect(response).to have_http_status(:not_found)
      end

      it 'is cloned with a write grant' do
        interpolate(scenario, user, write(scenario))

        expect(response).to have_http_status(:ok)
      end
    end

    describe 'an unbound public Session' do
      it 'accepts a write from a guest when nobody created it' do
        update(session)

        expect(response).to have_http_status(:ok)
      end

      it 'refuses a write from a guest when a user created it' do
        update(session(creator_id: creator.id))

        expect(response).to have_http_status(:forbidden)
      end

      it 'accepts a write from its creator' do
        update(session(creator_id: creator.id), creator)

        expect(response).to have_http_status(:ok)
      end

      it 'refuses a delete from its creator' do
        destroy(session(creator_id: creator.id), creator)

        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'an unbound private Session' do
      let(:scenario) { create(:scenario, user: creator, creator_id: creator.id, private: true) }

      it 'is readable by its creator with every scenario_users row deleted' do
        scenario
        ScenarioUser.delete_all
        show(scenario, creator)

        expect(response).to have_http_status(:ok)
      end

      it 'accepts a write from its creator with every scenario_users row deleted' do
        scenario
        ScenarioUser.delete_all
        update(scenario, creator)

        expect(response).to have_http_status(:ok)
      end

      it 'refuses anyone else' do
        show(scenario, user)

        expect(response).to have_http_status(:not_found)
      end

      it 'is readable with a grant naming it' do
        show(scenario, user, read(scenario))

        expect(response).to have_http_status(:ok)
      end
    end

    describe 'making a Session private' do
      it 'succeeds for the creator of an unbound Session without an owner row' do
        update(session(creator_id: creator.id), creator, nil, private: true)

        expect(response).to have_http_status(:ok)
      end

      it 'fails for an unbound Session nobody created' do
        update(session, user, nil, private: true)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    describe 'creating a Session from a private bound Session' do
      let(:source) { session(private: true, bound: true) }

      it 'succeeds with a read grant' do
        create_from(source, user, read(source))

        expect(response).to have_http_status(:ok)
      end

      it 'copies no roles from the source' do
        ScenarioUser.create!(
          scenario: source, user: creator, role_id: User::ROLES.key(:scenario_collaborator)
        )
        create_from(source, user, read(source))

        expect(created_scenario.scenario_users.pluck(:user_id)).to eq([user.id])
      end

      it 'stays private for a write grant' do
        create_from(source, user, write(source))

        expect(created_scenario).to be_private
      end

      it 'follows the caller for a read grant' do
        create_from(source, user, read(source))

        expect(created_scenario).not_to be_private
      end
    end

    describe 'roles sent by MyETM on save' do
      let(:scenario) { session(private: true, bound: true) }

      it 'are dropped while the rest of the save succeeds' do
        update(
          scenario, user, write(scenario),
          saved_scenario_users: [{ user_id: user.id, role_id: 3 }], keep_compatible: true
        )

        expect([response.status, scenario.scenario_users.count]).to eq([200, 0])
      end
    end

    describe 'listing Sessions' do
      it 'lists what the user created, and not what their grant names' do
        created = session(creator_id: user.id)
        granted = session(private: true, bound: true)
        session(creator_id: creator.id)

        get '/api/v3/scenarios',
          headers: access_token_header(user, :read, scenario_access: read(granted))

        expect(response.parsed_body['data'].pluck('id')).to contain_exactly(created.id)
      end
    end

    describe 'the Session users endpoints' do
      let(:headers) { access_token_header(creator, :delete) }
      let(:path) { "/api/v3/scenarios/#{create(:scenario, user: creator).id}/users" }
      let(:users) { [{ user_email: 'someone@quintel.com', role: 'scenario_viewer' }] }

      it 'answers every verb with 410 Gone' do
        statuses = [
          get(path, headers:),
          post(path, params: { scenario_users: users }, headers:, as: :json),
          put(path, params: { scenario_users: users }, headers:, as: :json),
          delete(path, params: { scenario_users: users }, headers:, as: :json)
        ]

        expect(statuses).to all(eq(410))
      end

      it 'points to MyETM' do
        get(path, headers:)

        expect(response.parsed_body['errors'].first).to include('managed on the scenario in MyETM')
      end
    end

    describe 'tagging a version' do
      let(:scenario) { session(private: true, bound: true) }

      def tag(access)
        post(
          "/api/v3/scenarios/#{scenario.id}/version",
          params: { description: 'Saved' },
          headers: access_token_header(user, :write, scenario_access: access)
        )
      end

      it 'succeeds with a write grant and no scenario_users row' do
        tag(write(scenario))

        expect(scenario.reload.scenario_version_tag&.description).to eq('Saved')
      end

      it 'is refused with a read grant' do
        tag(read(scenario))

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
