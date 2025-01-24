class AddQiFieldOnUser < ActiveRecord::Migration[7.0]

  DOMAINS = [
    '@quintel.com',
    '@energytransitionmodel.com',
    '@tennet.eu',
    '@netbeheernederland.nl',
    '@gasunie.nl',
    '@kalavasta.com',
    '@entsog.eu',
    '@sec.entsoe.eu',
    '@economy-bi.gov.uk',
    '@nijmegen.nl',
    '@rotterdam.nl',
    '@tudelft.nl',
    '@alliander.com',
    '@noord-holland.nl'
  ].freeze

  def up
    add_column :users, :include_in_qi_db, :boolean, default: false

    # User.where(DOMAINS.map { |domain| "email LIKE ?" }.join(' OR '), *DOMAINS.map { |domain| "%#{domain}" })
    #     .update_all(include_in_qi_db: true)
  end

  def down
    remove_column :users, :include_in_qi_db
  end
end
