require 'csv'

class Realestate
  include Mongoid::Document
  field :search_id, type: Integer
  field :bid, type: String
  field :site_slug, type: String
  field :name, type: String
  field :addr, type: String
  field :price, type: String
  field :built_at, type: String
  field :floor_plan, type: String
  field :occupied_area, type: String
  field :trafic_info, type: String
  field :detail_url, type: String
  field :search_cond, type: String
  field :searched_at, type: Time

  def self.to_csv(search_id)
    headers = %w[_id search_id 検索日時 スラッグ 物件名 詳細URL 物件ID 価格 所在地 交通情報 専有面積 間取り 築年月 検索条件]
    csv_data = CSV.generate(headers: headers, write_headers: true, force_quotes: true) do | csv |
      where(search_id: search_id).each do |row|
        csv << row.attributes.values
      end
    end
    csv_data.encode(Encoding::UTF_8)
    return csv_data
  end
end
