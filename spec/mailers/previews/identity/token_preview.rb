# Preview all emails at http://localhost:3000/rails/mailers/identity/token
class Identity::TokenPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/identity/token/created_token
  def created_token
    Identity::TokenMailer.created_token
  end

end
