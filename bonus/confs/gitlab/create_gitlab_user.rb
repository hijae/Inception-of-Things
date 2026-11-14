# Provisions a new GitLab user and associated namespace via Rails runner.
#
# This script interacts directly with the GitLab core backend to create a user 
# programmatically, bypassing web authentication. It ensures idempotency by 
# checking for existing users and dynamically resolves system dependencies 
# such as the default organization required in GitLab 18.x and later.
# It enforces strict state verification and exits with appropriate status codes.

begin
  admin = User.find_by(username: 'root') || User.first
  default_org = Organizations::Organization.default_organization || Organizations::Organization.first

  if admin.nil? || default_org.nil?
    puts "FAILED: Critical dependency missing."
    exit 1
  end

  target_username = 'kyoulee'
  
  params = {
    username: target_username,
    email: 'kyoulee@student.42seoul.kr',
    name: 'Kyoungkeun Lee',
    password: 'password@1234',
    password_confirmation: 'password@1234',
    skip_confirmation: true,
    organization_id: default_org.id
  }

  existing_user = User.find_by(username: target_username)
  if existing_user
    puts "SUCCESS: User '#{target_username}' is already provisioned."
    exit 0
  end

  response = Users::CreateService.new(admin, params).execute

  if response.success?
    puts "SUCCESS: User and namespace successfully created."
    exit 0
  else
    puts "FAILED: #{response.message}"
    exit 1
  end

rescue StandardError => e
  puts "ERROR: Exception occurred: #{e.message}"
  exit 1
end