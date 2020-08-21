User.create!(email: "jfalconer13.14@gmail.com",
                  password_digest: "123456",
                  first_name: "Jesse",
                  last_name: "Falconer"
                  )
Warehouse.create(name: "KBNF-HQ",
                street: Faker::Address.street_address,
                postal_code: Faker::Address.postcode,
                city: Faker::Address.city,
                province: "BC",
                country: "Canada",
                user_id: 1,
                status: "Active",
                description: Faker::Lorem.sentence
                )
Warehouse.create(name: "KBNF-REC",
                street: Faker::Address.street_address,
                postal_code: Faker::Address.postcode,
                city: Faker::Address.city,
                province: "Montserrado",
                country: "Liberia",
                user_id: 1,
                status: "Active",
                description: Faker::Lorem.sentence
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
