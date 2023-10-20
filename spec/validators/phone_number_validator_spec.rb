require "rails_helper"

RSpec.describe PhoneNumberValidator do
  subject do
    cls =
      Class.new do
        include ActiveModel::Model
        attr_accessor :phone_number

        def self.model_name
          ActiveModel::Name.new(self, nil, "temp")
        end

        validates :phone_number, phone_number: true
      end
    cls.new
  end

  describe "valid phone numbers" do
    it "should be valid" do
      [
        "7123456789",
        "07123456789",
        "07123 456789",
        "07123-456-789",
        "00447123456789",
        "00 44 7123456789",
        "+447123456789",
        "+44 7123 456 789",
        "+44 (0)7123 456 789"
        # "\u200B\t\t+44 (0)7123 \uFEFF 456 789 \r\n"
      ].each do |valid_number|
        subject.phone_number = valid_number
        expect(subject).to be_valid
      end
    end
  end

  describe "invalid phone numbers" do
    [
      [
        "is invalid", # "is too long",
        [
          "712345678910",
          "0712345678910",
          "0044712345678910",
          "+44 (0)7123 456 789 10"
        ]
      ],
      [
        "is invalid", # "is too short",
        ["0712345678", "00447123456", "004471234567", "+44 (0)7123 456 78"]
      ],
      [
        "is invalid", # "does not look like a UK mobile number",
        [
          "08081 570364",
          "+44 8081 570364",
          "0117 496 0860",
          "+44 117 496 0860",
          "020 7946 0991",
          "+44 20 7946 0991"
        ]
      ],
      [
        "is invalid", # "can only include: 0 1 2 3 4 5 6 7 8 9 ( ) + -",
        [
          "07890x32109",
          "07123 456789...",
          "07123 ☟☜⬇⬆☞☝",
          "07123☟☜⬇⬆☞☝",
          '07";DROP TABLE;"',
          "+44 07ab cde fgh",
          "ALPHANUM3R1C"
        ]
      ]
    ].each do |error_message, invalid_numbers|
      context "when #{error_message}" do
        it "should be invalid" do
          invalid_numbers.each do |invalid_number|
            subject.phone_number = invalid_number
            expect(subject).not_to be_valid
            expect(subject.errors[:phone_number]).to include(error_message)
          end
        end
      end
    end
  end
end
