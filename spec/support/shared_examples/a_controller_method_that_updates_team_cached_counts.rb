# frozen_string_literal: true

shared_examples "a method that updates team cached counts" do
  it "updates the team cached counts correctly" do
    cached = TeamCachedCounts.new(team)

    # 1. Warm the cache by fetching all counts once
    fetch_all_counts = ->(cc) do
      {
        import_issues: cc.import_issues,
        school_moves: cc.school_moves,
        unmatched_consent_responses: cc.unmatched_consent_responses
      }
    end

    fetch_all_counts.call(cached)

    # 2. Run the controller action provided by the including spec
    subject

    # 3. Read counts from cache after the action
    after_action_counts = fetch_all_counts.call(cached)

    # 4. Reset all cached counts for the team
    cached.reset_all!

    # 5. Recompute counts by fetching them again (this repopulates the cache)
    recomputed_counts = fetch_all_counts.call(cached)

    # 6. Ensure cached-after-action equals freshly recomputed values
    expect(after_action_counts).to eq(recomputed_counts)
  end
end
