class FdsjController < ApplicationController
  layout false
  def show_detail
    #detail_url = Realestate.find(params[:id]).pluck(:detail_url)
    detail_url = 'http://www.fudousan.or.jp/system/?act=l&type=12&pref=13&stype=l&city%5B%5D=13101&pl=l&ph=3&asl=l&ash=h&submitbtn=l'
    referer = Settings.site_url.fdsj.base + "system"
    response.headers['referer'] = referer
    redirect_to detail_url
  end
end
