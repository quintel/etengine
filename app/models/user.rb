# frozen_string_literal: true

class User < ApplicationRecord
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
