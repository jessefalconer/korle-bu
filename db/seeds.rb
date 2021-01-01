User.create!(email: "jesse@email.com",
                  first_name: "Jesse",
                  last_name: "Falconer",
                  role: "Admin",
                  password_digest: BCrypt::Password.create("123456")
                  )
User.create!(email: "aaron@email.com",
                  first_name: "Aaron",
                  last_name: "Fedora",
                  role: "Admin",
                  password_digest: BCrypt::Password.create("123456")
                  )
User.create!(email: "blaise_pascal@email.com",
                  first_name: "Blaise",
                  last_name: "Pascal",
                  role: "Shipping Manager",
                  password_digest: BCrypt::Password.create("123456")
                  )
User.create!(email: "leonhard_euler@email.com",
                  first_name: "Leonhard",
                  last_name: "Euler",
                  role: "Receiving Manager",
                  password_digest: BCrypt::Password.create("123456")
                  )
User.create!(email: "isaac_newton@email.com",
                  first_name: "Isaac",
                  last_name: "Newton",
                  role: "Volunteer",
                  password_digest: BCrypt::Password.create("123456")
                  )
User.create!(email: "maxwell_planck@email.com",
                  first_name: "Max",
                  last_name: "Planck",
                  role: "Volunteer",
                  password_digest: BCrypt::Password.create("123456")
                  )

Item.create(brand: "Tylenol",
            object: "acetaminophen",
            concentration: nil,
            concentration_units: nil,
            concentration_description: nil,
            standardized_size: nil,
            numerical_size_1: 8,
            numerical_units_1: "mg",
            numerical_description_1: "pills",
            numerical_size_2: nil,
            numerical_units_2: nil,
            numerical_description_2: nil,
            packaged_quantity: 60,
            verified: true,
            user_id: 1
            )

Item.create(brand: nil,
            object: "syringe  ",
            concentration: nil,
            concentration_units: nil,
            concentration_description: nil,
            standardized_size: nil,
            numerical_size_1: 20,
            numerical_units_1: "mL",
            numerical_description_1: "capacity",
            numerical_size_2: 0.55,
            numerical_units_2: "mm",
            numerical_description_2: "needle ",
            packaged_quantity: 10,
            verified: true,
            user_id: 1
            )

Item.create(brand: nil,
            object: "nitrile  gloves",
            concentration: nil,
            concentration_units: nil,
            concentration_description: nil,
            standardized_size: "XL",
            numerical_size_1: nil,
            numerical_units_1: nil,
            numerical_description_1: nil,
            numerical_size_2: nil,
            numerical_units_2: nil,
            numerical_description_2: nil,
            packaged_quantity: 50,
            verified: false,
            user_id: 1
            )

CATEGORIES = [
  "Hospital Pieces",
  "Hospital Equipment",
  "Hospital Maintenance",
  "Office Furniture",
  "Hospital Linen",
  "Medical Supplies - Misc",
  "Medical Supplies - Ophthalmology & ENT",
  "Medical Supplies - Neuro Surgery",
  "Medical Supplies - Anaesthesiology",
  "Medical Supplies - Operating Room",
  "Medical Supplies - Pulmonary and Cardiology",
  "Medical Supplies - Nursing Supplies",
  "Medical Supplies - Gastro, Intestinal and Urology",
  "Medical Supplies - Obstetrics and Gynaecology",
  "Medical Supplies - Orthopaedics",
  "Hospital Administration",
  "Hygiene Products",
  "Staff Physical Activity Supplies",
  "Staff Accomodation",
  "Housekeeping Department",
  "Pediatrics",
  "Bags Blankets"
].each do |cat|
  Category.create(name: cat, user_id: 1, description: Faker::Lorem.sentence)
end

WAREHOUSES = [
  "Delta", "Undetermined", "Liberia", "Tappita Hospital", "Sierra Leone", "Ahomka Foundation", "Nigeria"
].each { |name| Warehouse.create(name: name, user_id: User.first.id) }
