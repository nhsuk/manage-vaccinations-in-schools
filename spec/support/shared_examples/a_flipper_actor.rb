# frozen_string_literal: true

shared_examples_for "a Flipper actor" do
  describe "#flipper_id" do
    it "is a string" do
      expect(subject.flipper_id).to be_a(String)
    end

    it "is prefixed with the model name" do
      expect(subject.flipper_id).to start_with("#{subject.class.name}:")
    end

    it "is suffixed with the param" do
      expect(subject.flipper_id).to end_with(":#{subject.to_param}")
    end
  end
end
