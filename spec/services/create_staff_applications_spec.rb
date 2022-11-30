# frozen_string_literal: true

RSpec.describe CreateStaffApplications do
  let(:user) { create(:admin) }

  context 'when the user has no staff applications' do
    it 'creates staff applications for the user' do
      expect { described_class.call(user) }
        .to change { user.staff_applications.count }
        .from(0)
        .to(ETEngine::StaffApplications.applications.count)
    end

    it 'creates OAuth applications for the user' do
      expect { described_class.call(user) }
        .to change { user.oauth_applications.count }
        .from(0)
        .to(ETEngine::StaffApplications.applications.count)
    end
  end

  context 'when the user has one staff application' do
    before do
      etmodel = ETEngine::StaffApplications.find(:etmodel)

      user.staff_applications.create!(
        name: etmodel.key,
        application: user.oauth_applications.create!(etmodel.to_model_attributes)
      )
    end

    it 'creates staff applications for the user' do
      expect { described_class.call(user) }
        .to change { user.staff_applications.count }
        .from(1)
        .to(ETEngine::StaffApplications.applications.count)
    end

    it 'creates OAuth applications for the user' do
      expect { described_class.call(user) }
        .to change { user.oauth_applications.count }
        .from(1)
        .to(ETEngine::StaffApplications.applications.count)
    end
  end
end
