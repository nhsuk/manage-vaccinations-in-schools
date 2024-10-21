# frozen_string_literal: true

describe NotifySafeEmailValidator do
  subject(:model) { Validatable.new(email:) }

  before do
    stub_const("Validatable", Class.new).class_eval do
      include ActiveModel::Model
      attr_accessor :email
      validates :email, notify_safe_email: true
    end

    stub_const("ValidatableAllowNil", Class.new).class_eval do
      include ActiveModel::Model
      attr_accessor :email
      validates :email, notify_safe_email: { allow_nil: true }
    end

    stub_const("ValidatableAllowBlank", Class.new).class_eval do
      include ActiveModel::Model
      attr_accessor :email
      validates :email, notify_safe_email: { allow_blank: true }
    end
  end

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
  ].each do |value|
    context "with #{value}" do
      let(:email) { value }

      it { should be_valid }
    end
  end

  [
    nil,
    "",
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
  ].each do |value|
    context "with #{value}" do
      let(:email) { value }

      it { should be_invalid }
    end
  end

  context "when allowing nil values" do
    subject(:model) { ValidatableAllowNil.new(email:) }

    let(:email) { nil }

    it { should be_valid }
  end

  context "when allowing blank values" do
    subject(:model) { ValidatableAllowBlank.new(email:) }

    let(:email) { "" }

    it { should be_valid }
  end
end
