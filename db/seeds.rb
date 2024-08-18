User.find_each do |user, index|
  user.password_digest = BCrypt::Password.create("123456")
  user.save(:validate => false)
end
