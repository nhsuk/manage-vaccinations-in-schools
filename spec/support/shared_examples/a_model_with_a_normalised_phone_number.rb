# frozen_string_literal: true

shared_examples_for "a model with a normalised phone number" do |column = :phone|
  it { should normalize(column).from(nil).to(nil) }
  it { should normalize(column).from("").to(nil) }

  it do
    expect(subject).to normalize(column).from("  01234567890 ").to(
      "01234 567890"
    )
  end

  it { should normalize(column).from("1234567890").to("01234 567890") }

  it do
    expect(subject).to normalize(column).from("+441234567890").to(
      "01234 567890"
    )
  end

  it do
    expect(subject).to normalize(column).from("0033123456789").to(
      "+33 1 23 45 67 89"
    )
  end
end
