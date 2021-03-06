class User < ActiveRecord::Base
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Role-management behaviors.
  include Hydra::RoleManagement::UserRoles

# Connects this user object to Sufia behaviors. 
  include Sufia::User
  include Sufia::UserUsageStats





  if Blacklight::Utils.needs_attr_accessible?

    attr_accessible :email, :password, :password_confirmation
  end
# Connects this user object to Blacklights Bookmarks. 
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  
    # check if user is admin
  def admin?
    # first we pull all users from the Role db
    admin_users = []
    r = Role.find_by name: "admin"
    # then we extract the emails
    r.users.each do |user|
      admin_users << user['email']
    end
    # finally we compare with the current user
    if admin_users.include? email
      return true
    else
      return false
    end
  end

end
