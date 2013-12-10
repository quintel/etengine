# == Schema Information
#
# Table name: users
#
#  id                 :integer(4)      not null, primary key
#  name               :string(255)     not null
#  email              :string(255)     not null
#  company_school     :string(255)
#  allow_news         :boolean(1)      default(TRUE)
#  heared_first_at    :string(255)     default("..")
#  crypted_password   :string(255)
#  password_salt      :string(255)
#  persistence_token  :string(255)     not null
#  perishable_token   :string(255)     not null
#  login_count        :integer(4)      default(0), not null
#  failed_login_count :integer(4)      default(0), not null
#  last_request_at    :datetime
#  current_login_at   :datetime
#  last_login_at      :datetime
#  current_login_ip   :string(255)
#  last_login_ip      :string(255)
#  role_id            :integer(4)
#  created_at         :datetime
#  updated_at         :datetime
#  openid_identifier  :string(255)
#  phone_number       :string(255)
#  group              :string(255)
#  trackable          :string(255)     default("0")
#  send_score         :boolean(1)      default(FALSE)
#  new_round          :boolean(1)
#

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable, :registerable
  devise :database_authenticatable, :recoverable, :rememberable,
         :trackable, :validatable

  has_many :scenarios
  belongs_to :role

  validates_format_of   :phone_number,
                        :message => " is niet goed ingevuld.",
                        :with => /\A[\(\)0-9\- \+\.]{10,20}\z/,
                        :if => Proc.new { |o| !o.phone_number.nil? }

  validates_presence_of :name

  def admin?
    self.role.try(:name) == "admin"
  end
end
