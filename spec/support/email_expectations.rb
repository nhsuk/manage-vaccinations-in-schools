module EmailExpectations
  def expect_email_to(to, template, nth = :first)
    perform_enqueued_jobs

    email = ActionMailer::Base.deliveries.send(nth)
    expect(email.to).to eq [to]
    expect(email[:template_id].value).to eq template
  end
end
