# frozen_string_literal: true

shared_examples_for "a model with a normalised email address" do |column = :email|
  it { should normalize(column).from(nil).to(nil) }
  it { should normalize(column).from("").to(nil) }

  it do
    expect(subject).to normalize(column).from("  joHn@doe.com ").to(
      "john@doe.com"
    )
  end
end
