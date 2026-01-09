# frozen_string_literal: true

describe Import::BulkRemoveParentPolicy do
  subject(:policy) { described_class }

  let(:poc_only_team) { create(:team, :poc_only) }
  let(:upload_only_team) { create(:team, :upload_only) }
  let(:poc_only_user) { create(:nurse, teams: [poc_only_team]) }
  let(:upload_only_user) { create(:nurse, teams: [upload_only_team]) }
  let(:import) { create(:class_import) }

  permissions :index?, :destroy?, :edit?, :show?, :update? do
    it { should_not permit(poc_only_user, import) }
    it { should_not permit(upload_only_user, import) }
  end

  permissions :new?, :create? do
    context "with feature flag enabled" do
      before { Flipper.enable(:import_bulk_remove_parents) }

      it { should permit(poc_only_user, import) }
      it { should_not permit(upload_only_user, import) }
    end

    context "with feature flag disabled" do
      before { Flipper.disable(:import_bulk_remove_parents) }

      it { should_not permit(poc_only_user, import) }
      it { should_not permit(upload_only_user, import) }
    end
  end
end
