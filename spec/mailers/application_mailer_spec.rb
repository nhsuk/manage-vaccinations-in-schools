# frozen_string_literal: true

describe ApplicationMailer do
  subject(:mail) do
    mailer_class.with(session:, parent:, patient:).example_email
  end

  let(:mailer_class) do
    Class.new(ApplicationMailer) do
      def example_email
        app_template_mail(GOVUK_NOTIFY_EMAIL_TEMPLATES.keys.first)
      end
    end
  end

  let(:programmes) { create_list(:programme, 1) }
  let(:organisation) { create(:organisation, programmes:) }
  let(:team) { create(:team, organisation:) }

  let(:location) { create(:school, team:) }
  let(:session) { create(:session, location:, organisation:, programmes:) }
  let(:parent) { create(:parent) }
  let(:patient) { create(:patient) }

  describe "#reply_to_id" do
    subject { mail.reply_to_id }

    it { should be_nil }

    context "when the organisation has a reply_to_id" do
      let(:reply_to_id) { SecureRandom.uuid }

      let(:organisation) { create(:organisation, programmes:, reply_to_id:) }

      it { should eq(reply_to_id) }
    end

    context "when the team has a reply_to_id" do
      let(:reply_to_id) { SecureRandom.uuid }

      let(:team) { create(:team, organisation:, reply_to_id:) }

      it { should eq(reply_to_id) }
    end

    context "when the team and the organisation has a reply_to_id" do
      let(:reply_to_id) { SecureRandom.uuid }

      let(:organisation) do
        create(:organisation, programmes:, reply_to_id: SecureRandom.uuid)
      end
      let(:team) { create(:team, organisation:, reply_to_id:) }

      it { should eq(reply_to_id) }
    end
  end
end
