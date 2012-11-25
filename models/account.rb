class Account < CouchRest::Model::Base
  attr_accessor :password, :password_confirmation

  # Properties
  #property :id,								Serial
  property :name,							String
  property :title,						String
  property :email,						String
  property :crypted_password,	String
  property :role,							String
  property :balance,					Float
  property :created_at,				DateTime

  view_by :email

  # Validations
  validates_presence_of     :email, :role
  validates_presence_of     :password,                   :if => :password_required
  validates_presence_of     :password_confirmation,      :if => :password_required
  validates_length_of       :password, :within => 4..40, :if => :password_required
  validates_confirmation_of :password,                   :if => :password_required
  validates_length_of       :email,    :within => 3..100
  validates_format_of       :email,    :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  validates_format_of       :role,     :with => /[A-Za-z]/
  validate                  :unique_email_validator

  # Callbacks
  before_save :encrypt_password, :if => :password_required

  ##
  # This method is for authentication purpose
  #
  def self.authenticate(email, password)
    account = find_by_email(email)
    account if account && account.has_password?(password)
  end

  def has_password?(password)
    ::BCrypt::Password.new(crypted_password) == password
  end

  ##
  # This method is used by AuthenticationHelper
  #
  def self.find_by_id(id)
    get(id)
  end

  private
  def encrypt_password
    self.crypted_password = ::BCrypt::Password.create(password)
  end

  def password_required
    crypted_password.blank? || password.present?
  end

  def unique_email_validator
    account = self.class.find_by_email(email)

    # didn't find email in the database
    return if account.nil?

    # account with same email in database is this account
    return if has_key?('_id') && self['_id'] == account['_id']

    errors.add(:email, "is not unique")
  end
end