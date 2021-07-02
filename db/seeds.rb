# Uncomment these for development seeding and prior to inserting SQL dump

# u = User.new(email: "jesse@email.com",
#                   first_name: "Jesse",
#                   last_name: "Falconer",
#                   role: "Admin",
#                   status: "Active",
#                   password_digest: BCrypt::Password.create("123456"),
#                   phone: "1234567"
#                   )
# u.save(:validate => false)
# u = User.new(email: "aaron@email.com",
#                   first_name: "Aaron",
#                   last_name: "Fedora",
#                   role: "Admin",
#                   password_digest: BCrypt::Password.create("123456"),
#                   phone: "1234567"
#                   )
# u.save(:validate => false)
# u = User.new(email: "blaise_pascal@email.com",
#                   first_name: "Blaise",
#                   last_name: "Pascal",
#                   role: "Shipping Manager",
#                   password_digest: BCrypt::Password.create("123456"),
#                   phone: "1234567"
#                   )
# u.save(:validate => false)
# u = User.new(email: "leonhard_euler@email.com",
#                   first_name: "Leonhard",
#                   last_name: "Euler",
#                   role: "Receiving Manager",
#                   password_digest: BCrypt::Password.create("123456"),
#                   phone: "1234567"
#                   )
# u.save(:validate => false)
# u = User.new(email: "isaac_newton@email.com",
#                   first_name: "Isaac",
#                   last_name: "Newton",
#                   role: "Volunteer",
#                   password_digest: BCrypt::Password.create("123456"),
#                   phone: "1234567"
#                   )
# u.save(:validate => false)
# u = User.new(email: "maxwell_planck@email.com",
#                   first_name: "Max",
#                   last_name: "Planck",
#                   role: "Volunteer",
#                   password_digest: BCrypt::Password.create("123456"),
#                   phone: "1234567"
#                   )
# u.save(:validate => false)

# CATEGORIES = [
#   "Hospital Pieces",
#   "Hospital Equipment",
#   "Hospital Maintenance",
#   "Office Furniture",
#   "Hospital Linen",
#   "Medical Supplies - Misc",
#   "Medical Supplies - Ophthalmology & ENT",
#   "Medical Supplies - Neuro Surgery",
#   "Medical Supplies - Anaesthesiology",
#   "Medical Supplies - Operating Room",
#   "Medical Supplies - Pulmonary and Cardiology",
#   "Medical Supplies - Nursing Supplies",
#   "Medical Supplies - Gastro, Intestinal and Urology",
#   "Medical Supplies - Obstetrics and Gynaecology",
#   "Medical Supplies - Orthopaedics",
#   "Hospital Administration",
#   "Hygiene Products",
#   "Staff Physical Activity Supplies",
#   "Staff Accomodation",
#   "Housekeeping Department",
#   "Pediatrics",
#   "Bags Blankets"
# ].each do |cat|
#   Category.create(name: cat, user_id: 1, description: Faker::Lorem.sentence)
# end

# WAREHOUSES = [
#   "Main Warehouse", "Undetermined", "Liberia", "Tappita Hospital", "Sierra Leone", "Ahomka Foundation", "Nigeria"
# ].each { |name| Warehouse.create(name: name, user_id: User.first.id, status: "Active") }
