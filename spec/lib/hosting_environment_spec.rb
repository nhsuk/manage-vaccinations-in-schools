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
end
