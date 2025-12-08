# frozen_string_literal: true

describe "Bulk remove parents" do
  context "When there are no associated consents" do
    before { given_i_am_signed_in }

    scenario "All parent relationships are removed" do
      when_i_go_to_the_page_for_the_class_import
      and_i_click_remove_all_parent_child_relationships_from_import
      then_i_should_see_the_bulk_parent_removal_form

      when_i_click_continue

      then_i_should_see_the_all_parent_relationships_removed_success_flash
      and_all_parent_relationships_from_the_import_should_be_deleted
    end
  end

  context "When there are associated consents" do
    before do
      given_i_am_signed_in
      and_a_consent_exists_in_the_import
    end

    scenario "Parent relationships are removed except for those with consent" do
      when_i_go_to_the_page_for_the_class_import
      and_i_click_remove_all_parent_child_relationships_from_import
      then_i_should_see_the_bulk_parent_removal_form
      with_information_about_parent_relationships_with_associated_consents

      when_i_choose_only_parent_child_relationships_with_no_associated_consents
      when_i_click_continue

      then_i_should_see_the_parent_relationships_without_associated_consents_removed_success_flash
      and_all_parent_relationships_without_associated_consent_from_the_import_should_be_deleted
      and_the_parent_relationship_with_associated_consent_from_the_import_should_not_be_deleted
    end

    scenario "All parent relationships are removed and consent invalidated" do
      when_i_go_to_the_page_for_the_class_import
      and_i_click_remove_all_parent_child_relationships_from_import
      then_i_should_see_the_bulk_parent_removal_form
      with_information_about_parent_relationships_with_associated_consents

      when_i_choose_remove_all_parent_child_relationships
      when_i_click_continue

      then_i_should_see_the_all_parent_relationships_removed_success_flash
      and_all_parent_relationships_from_the_import_should_be_deleted
      and_the_consent_should_be_invalidated
    end
  end

  def given_i_am_signed_in
    programmes = [Programme.hpv]
    team = create(:team, :with_one_nurse, programmes:)

    @user = team.users.first

    @class_import = create(:class_import, :processed, team:)
    @patients = create_list(:patient, 5, school: @class_import.location)
    @patients.each do |patient|
      parent = create(:parent)
      parent_relationship = create(:parent_relationship, parent:, patient:)
      @class_import.patients << patient
      @class_import.parent_relationships << parent_relationship
      @class_import.parents << parent
      patient.reload
    end

    sign_in @user
  end

  def and_a_consent_exists_in_the_import
    @consent =
      create(
        :consent,
        patient: @patients.first,
        parent: @patients.first.parents.sole,
        programme: Programme.hpv
      )
  end

  def when_i_go_to_the_page_for_the_class_import
    visit class_import_path(@class_import)
  end

  def and_i_click_remove_all_parent_child_relationships_from_import
    click_on "Remove all parent-child relationships from import"
  end

  def then_i_should_see_the_bulk_parent_removal_form
    expect(page).to have_content(
      "Are you sure you want to remove all parent-child relationships included in this import?"
    )
  end

  def with_information_about_parent_relationships_with_associated_consents
    expect(page).to have_content(
      "One or more parents in this import have given consent responses for children in this import."
    )
    expect(page).to have_content(@consent.patient.full_name)
    expect(page).to have_content(@consent.parent.full_name)
  end

  def when_i_choose_only_parent_child_relationships_with_no_associated_consents
    choose "Only remove parent–child relationships where no consent response has been submitted"
  end

  def when_i_choose_remove_all_parent_child_relationships
    choose "Remove all parent–child relationships included in this import"
  end

  def when_i_click_continue
    click_on "Continue"
  end

  def then_i_should_see_the_all_parent_relationships_removed_success_flash
    expect(page).to have_content(
      "All parent-child relationships included in this import have been removed"
    )
  end

  def then_i_should_see_the_parent_relationships_without_associated_consents_removed_success_flash
    expect(page).to have_content(
      "Parent–child relationships without a submitted consent response have been removed."
    )
  end

  def and_all_parent_relationships_from_the_import_should_be_deleted
    @patients.each { |patient| expect(patient.reload.parents).to be_empty }
  end

  def and_all_parent_relationships_without_associated_consent_from_the_import_should_be_deleted
    @patients
      .drop(1)
      .each { |patient| expect(patient.reload.parents).to be_empty }
  end

  def and_the_parent_relationship_with_associated_consent_from_the_import_should_not_be_deleted
    patient = @patients.first.reload
    expect(patient.parents.count).to eq(1)
    expect(patient.consents.count).to eq(1)
  end

  def and_the_consent_should_be_invalidated
    @consent.reload
    expect(@consent.invalidated_at).to be_present
    expect(@consent.notes).to include("Consent invalidated")
    expect(@consent.notes).to include(@user.full_name)
    expect(@consent.notes).to include(
      "removed all parent-child relationships from an import"
    )
  end
end
