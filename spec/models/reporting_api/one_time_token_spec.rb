# frozen_string_literal: true

# == Schema Information
#
# Table name: reporting_api_one_time_tokens
#
#  cis2_info  :jsonb            not null
#  token      :string           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_reporting_api_one_time_tokens_on_created_at  (created_at)
#  index_reporting_api_one_time_tokens_on_token       (token) UNIQUE
#  index_reporting_api_one_time_tokens_on_user_id     (user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

describe ReportingAPI::OneTimeToken do
  subject(:token) do
    described_class.new(user_id: user.id, token: SecureRandom.hex(32))
  end

  let(:user) { create(:user) }

  let(:cis2_info) do
    {
      "user" => {
        "id" => 1234,
        "email" => "test.user@example.com"
      },
      "org" => {
        "id" => 2345,
        "name" => "Test Org 1"
      }
    }
  end

  describe "validations" do
    it { should validate_uniqueness_of(:user_id) }
    it { should validate_presence_of(:user_id) }
    it { should validate_uniqueness_of(:token) }
    it { should validate_presence_of(:token) }
  end

  describe ".generate!" do
    let(:generate) do
      described_class.generate!(user_id: user_id, cis2_info: cis2_info)
    end

    context "given a valid user_id" do
      let(:user_id) { user.id }

      it "creates a OneTimeToken with the given user_id" do
        expect { generate }.to change(
          described_class.where(user_id: user_id),
          :count
        ).by(1)
      end

      describe "the generated OneTimeToken" do
        let(:generated_token) { described_class.find_by(user_id: user_id) }

        it "has the given cis2_info" do
          generate
          expect(generated_token.cis2_info).to eq(cis2_info)
        end

        it "has a hex string as :token" do
          generate
          expect(generated_token.token).to match(/[a-fA-F0-9]{32,}/)
        end
      end
    end

    context "given an invalid user_id" do
      let(:user_id) { nil }

      it "raises an ActiveRecord::RecordInvalid error" do
        expect { generate }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "does not generate a token" do
        expect {
          begin
            generate
          rescue ActiveRecord::RecordInvalid => _e
            nil
          end
        }.not_to change(described_class, :count)
      end
    end
  end

  describe "#find_or_generate_for!" do
    context "given a valid user" do
      context "when there is no existing token for that user" do
        before { described_class.where(user: user).delete_all }

        it "generates a token for the user" do
          expect {
            described_class.find_or_generate_for!(user: user)
          }.to change(described_class.where(user_id: user.id), :count).by(1)
        end

        it "returns the new token" do
          expect(described_class.find_or_generate_for!(user: user)).to be_a(
            described_class
          )
        end
      end

      context "when there is an existing token for the user" do
        let!(:existing_token) do
          create(
            :reporting_api_one_time_token,
            user_id: user.id,
            token: "testtoken"
          )
        end

        context "that has not expired" do
          it "returns the existing token" do
            expect(described_class.find_or_generate_for!(user: user)).to eq(
              existing_token
            )
          end

          it "does not create a new token" do
            expect {
              described_class.find_or_generate_for!(user: user)
            }.not_to change(described_class.where(user_id: user.id), :count)
          end
        end

        context "which has expired" do
          before { existing_token.update!(created_at: Time.current - 1.year) }

          it "deletes the existing token" do
            described_class.find_or_generate_for!(user: user)
            expect(described_class.find_by(existing_token.attributes)).to be_nil
          end

          describe "the returned token" do
            let(:returned_token) do
              described_class.find_or_generate_for!(
                user: user,
                cis2_info: cis2_info
              )
            end

            it "is not the existing token" do
              expect(returned_token).not_to eq(existing_token)
            end

            it "has the given user id" do
              expect(returned_token.user_id).to eq(user.id)
            end

            it "has the given cis2_info" do
              expect(returned_token.cis2_info).to eq(cis2_info)
            end
          end
        end
      end
    end
  end

  describe "#jwt_payload" do
    let(:result) { token.jwt_payload }

    it "has iat set to the current time as an integer" do
      expect(result["iat"]).to be_within(1000).of(Time.current.utc.to_i)
    end

    it "has a data hash" do
      expect(result["data"]).to be_a(Hash)
    end

    describe "the data hash" do
      let(:data) { result["data"] }

      it "has the user as json" do
        expect(data["user"]).to eq(token.user.as_json)
      end

      it "has the cis2_info as json" do
        expect(data["cis2_info"]).to eq(token.cis2_info.as_json)
      end
    end
  end

  describe "#to_jwt" do
    let(:result) { token.to_jwt }
    let(:decoded_payload) do
      JWT.decode(
        result,
        Settings.reporting_api.client_app.secret,
        true,
        { algorithm: ReportingAPI::OneTimeToken::JWT_SIGNING_ALGORITHM }
      ).first
    end

    it "returns a JWT signed with the Mavis reporting app secret" do
      expect {
        JWT.decode(
          result,
          Settings.reporting_api.client_app.secret,
          true,
          { algorithm: ReportingAPI::OneTimeToken::JWT_SIGNING_ALGORITHM }
        )
      }.not_to raise_error
    end

    it "has the jwt_payload" do
      freeze_time { expect(decoded_payload).to eq(token.jwt_payload) }
    end
  end
end
