class TestMailer < ApplicationMailer
  add_template_helper(ApplicationHelper)
  def test_email
    @now = Time.now
    mail from: 'honcho@giris.jp', to: 'xo@sea.plala.or.jp', subject: 'メール送信テスト'
  end
end
