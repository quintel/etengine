class AddUriToOAuthApplication < ActiveRecord::Migration[7.0]
  def up
    add_column :oauth_applications, :uri, :string, null: false, after: :secret

    OAuthApplication.find_each do |app|
      next unless app.redirect_uri.present?

      uri = URI.parse(app.redirect_uri)
      uri.path = ''

      app.update(uri: uri.to_s)
    end
  end

  def down
    delete_cloumn :oauth_applications, :uri
  end
end
