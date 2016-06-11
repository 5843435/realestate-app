module ApplicationHelper
  def csv_download_url(search_id)
    Settings.site_url.app.base + 'csv/download/%s.csv' % search_id
  end
end
