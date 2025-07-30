# frozen_string_literal: true

describe HostingEnvironment do
  let(:hosting_environment) { nil }
  let(:pr_number) { nil }

  around do |example|
    ClimateControl.modify(
      SENTRY_ENVIRONMENT: hosting_environment,
      HEROKU_PR_NUMBER: pr_number
    ) { example.run }
  end

  describe "#name" do
    subject { described_class.name }

    context "when the environment variable is set" do
      let(:hosting_environment) { "production" }

      it { should eq("production") }
    end

    context "when the environment variable isn't set" do
      it { should eq("development") }
    end
  end

  describe "#title" do
    subject { described_class.title }

    context "when the environment variable is set" do
      let(:hosting_environment) { "production" }

      it { should eq("Production") }
    end

    context "when in the QA environment" do
      let(:hosting_environment) { "qa" }

      it { should eq("QA") }
    end

    context "when in a pull request environment" do
      let(:hosting_environment) { "review" }
      let(:pr_number) { "123" }

      it { should eq("PR 123") }
    end

    context "when the environment variable isn't set" do
      it { should eq("Development") }
    end
  end

  describe "#title_in_sentence" do
    subject { described_class.title_in_sentence }

    context "when the environment variable is set" do
      let(:hosting_environment) { "production" }

      it { should eq("production") }
    end

    context "when in the QA environment" do
      let(:hosting_environment) { "qa" }

      it { should eq("QA") }
    end

    context "when in a pull request environment" do
      let(:hosting_environment) { "review" }
      let(:pr_number) { "123" }

      it { should eq("PR 123") }
    end

    context "when the environment variable isn't set" do
      it { should eq("development") }
    end
  end

  describe "#colour" do
    subject { described_class.colour }

    context "when the environment variable is set" do
      let(:hosting_environment) { "production" }

      it { should eq("blue") }
    end

    context "when in the QA environment" do
      let(:hosting_environment) { "qa" }

      it { should eq("orange") }
    end

    context "when in a pull request environment" do
      let(:hosting_environment) { "review" }

      it { should eq("purple") }
    end

    context "when the environment variable isn't set" do
      it { should eq("white") }
    end
  end

  describe "#theme_colour" do
    subject { described_class.theme_colour }

    context "when the environment variable is set" do
      let(:hosting_environment) { "production" }

      it { should eq("#005eb8") }
    end

    context "when in the QA environment" do
      let(:hosting_environment) { "qa" }

      it { should eq("#ffdc8e") }
    end

    context "when in a pull request environment" do
      let(:hosting_environment) { "review" }

      it { should eq("#d6cce3") }
    end

    context "when the environment variable isn't set" do
      it { should eq("#fff") }
    end
  end
end
