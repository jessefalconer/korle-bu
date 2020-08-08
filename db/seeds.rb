# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
User.create(email: "jfalconer3.14@gmail.com",
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
                notes: Faker::Lorem.sentence
                )
Warehouse.create(name: "KBNF-REC",
                street: Faker::Address.street_address,
                postal_code: Faker::Address.postcode,
                city: Faker::Address.city,
                province: "Montserrado",
                country: "Liberia",
                user_id: 1,
                status: "Active",
                notes: Faker::Lorem.sentence
                )

20.times do
  Item.create(name: Faker::Appliance.equipment,
              user_id: 1
              )
end
