# == Schema Information
#
# Table name: parents
#
#  id                   :bigint           not null, primary key
#  contact_method       :integer
#  contact_method_other :text
#  email                :string
#  name                 :string
#  phone                :string
#  relationship         :integer
#  relationship_other   :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
FactoryBot.define do
  factory :parent do
    transient do
      random { Random.new }

      sex { %w[male female].sample(random:) }
      last_name { Faker::Name.last_name }
      first_name do
        if sex == "male"
          Faker::Name.masculine_name
        else
          Faker::Name.feminine_name
        end
      end
    end

    name { "#{first_name} #{last_name}" }
    relationship { sex == "male" ? "father" : "mother" }
    email { "#{name.downcase.gsub(" ", ".")}#{random.rand(100)}@example.com" }
    phone { "07700 900#{random.rand(0..999).to_s.rjust(3, "0")}" }

    trait :mum do
      transient { sex { "female" } }
      relationship { "mother" }
    end

    trait :dad do
      transient { sex { "male" } }
      relationship { "father" }
    end

    trait :randomly_mum_or_dad do
      send %i[mum dad].sample
    end
  end
end
