class CsvController < ApplicationController
  before_action :basic
  layout false
  def download
    search_id = params[:search_id]
    csv_data = Realestate.to_csv(search_id)
    # if Rails.env == 'development'
    #   filename = search_id + '.csv'
    #   file = csv_data
    #   type = 'text/csv; charset=utf-8'
    # elsif Rails.env == 'production'
      zip = Zip::Archive.open_buffer(Zip::CREATE)
      zip.add_buffer(search_id + '.csv', csv_data)
      zip.encrypt(Rails.application.secrets.zip_password)
      file = zip.read
      zip.close
      type = 'application/x-compress'
      filename = search_id + '.zip'
    # end

    respond_to do |format|
      format.csv { send_data file, type: type, filename: filename }
    end
  end
end
