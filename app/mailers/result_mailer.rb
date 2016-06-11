class ResultMailer < ApplicationMailer
  add_template_helper(ApplicationHelper)
  def notify_success(search_id)
    @search_id = search_id
    from = Rails.application.secrets.mail_from
    to = Rails.application.secrets.mail_to
    subject = Settings.mail_success_subject
    mail from: from, to: to, subject: subject
  end

  def notify_error(error)
    @error = error
    from = Rails.application.secrets.mail_from
    to = Rails.application.secrets.mail_to
    subject = Settings.mail_error_subject
    mail from: from, to: to, subject: subject
  end
end
