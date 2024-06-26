# frozen_string_literal: true

require "rails_helper"

describe NotifySafeEmailValidator do
  subject(:model) do
    cls =
      Class.new do
        include ActiveModel::Validations
        attr_accessor :email
        validates :email, notify_safe_email: true
      end
    cls.new
  end

  let(:valid_email_addresses) do
    [
      "email@domain.com",
      "email@domain.COM",
      "firstname.lastname@domain.com",
      "firstname.o'lastname@domain.com",
      "email@subdomain.domain.com",
      "firstname+lastname@domain.com",
      "1234567890@domain.com",
      "email@domain-one.com",
      "_______@domain.com",
      "email@domain.name",
      "email@domain.superlongtld",
      "email@domain.co.jp",
      "firstname-lastname@domain.com",
      # "info@german-financial-services.vermögensberatung",
      "info@german-financial-services.reallylongarbitrarytldthatiswaytoohugejustincase",
      # "japanese-info@例え.テスト",
      "email@double--hyphen.com"
    ]
  end

  let(:invalid_email_addresses) do
    [
      "email@123.123.123.123",
      "email@[123.123.123.123]",
      "plainaddress",
      "@no-local-part.com",
      "Outlook Contact <outlook-contact@domain.com>",
      "no-at.domain.com",
      "no-tld@domain",
      ";beginning-semicolon@domain.co.uk",
      "middle-semicolon@domain.co;uk",
      "trailing-semicolon@domain.com;",
      '"email+leading-quotes@domain.com',
      'email+middle"-quotes@domain.com',
      '"quoted-local-part"@domain.com',
      '"quoted@domain.com"',
      "lots-of-dots@domain..gov..uk",
      "two-dots..in-local@domain.com",
      "multiple@domains@domain.com",
      "spaces in local@domain.com",
      "spaces-in-domain@dom ain.com",
      "underscores-in-domain@dom_ain.com",
      "pipe-in-domain@example.com|gov.uk",
      "comma,in-local@gov.uk",
      "comma-in-domain@domain,gov.uk",
      "pound-sign-in-local£@domain.com",
      "local-with-’-apostrophe@domain.com",
      "local-with-”-quotes@domain.com",
      "domain-starts-with-a-dot@.domain.com",
      "brackets(in)local@domain.com",
      "email-too-long-#{"a" * 320}@example.com",
      "incorrect-punycode@xn---something.com"
    ]
  end

  it "validates valid email addresses" do
    valid_email_addresses.each do |email|
      model.email = email
      expect(model).to be_valid
    end
  end

  it "does not validate invalid email addresses" do
    invalid_email_addresses.each do |email|
      model.email = email
      expect(model).not_to be_valid
    end
  end
end
