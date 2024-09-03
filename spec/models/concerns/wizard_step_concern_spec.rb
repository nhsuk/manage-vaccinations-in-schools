# frozen_string_literal: true

class Dummy
  include ActiveModel::Model
  include WizardStepConcern
end

describe WizardStepConcern do
  describe ".wizard_step" do
    subject { Dummy.new.wizard_step }

    it { should be_nil }
  end

  describe "on_wizard_step" do
    subject { Dummy.new }

    before do
      Dummy.class_eval do
        attr_accessor :foo, :bar, :qux

        def wizard_steps
          %i[first_step optional_step last_step]
        end

        on_wizard_step :first_step do
          validates :foo, presence: true
        end

        on_wizard_step :optional_step, exact: true do
          validates :bar, presence: true
        end

        on_wizard_step :last_step do
          validates :qux, presence: true
        end
      end
    end

    it { should be_valid }

    context "when no step is set" do
      before { subject.valid?(:update) }

      it "runs all required validations" do
        expect(subject.errors).not_to be_empty
        expect(subject.errors[:foo]).to include("can't be blank")
        expect(subject.errors[:bar]).to be_empty
        expect(subject.errors[:qux]).to include("can't be blank")
      end
    end

    context "when updating on the first step" do
      before do
        subject.wizard_step = :first_step
        subject.valid?(:update)
      end

      it "runs only first step validations" do
        expect(subject.errors).not_to be_empty
        expect(subject.errors[:foo]).to include("can't be blank")
        expect(subject.errors[:bar]).to be_empty
        expect(subject.errors[:qux]).to be_empty
      end
    end

    context "when updating on the optional step" do
      before do
        subject.wizard_step = :optional_step
        subject.valid?(:update)
      end

      it "runs first and optional step validations" do
        expect(subject.errors).not_to be_empty
        expect(subject.errors[:foo]).to include("can't be blank")
        expect(subject.errors[:bar]).to include("can't be blank")
        expect(subject.errors[:qux]).to be_empty
      end
    end

    context "when updating on the last step" do
      before do
        subject.wizard_step = :last_step
        subject.valid?(:update)
      end

      it "runs first and last step validations" do
        expect(subject.errors).not_to be_empty
        expect(subject.errors[:foo]).to include("can't be blank")
        expect(subject.errors[:bar]).to be_empty
        expect(subject.errors[:qux]).to include("can't be blank")
      end
    end
  end
end
