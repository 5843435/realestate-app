class Cond
  include Mongoid::Document
  field :site_slug, type: String
  field :building_type, type: String
  field :area1, type: String
  field :area2, type: String
  field :price_min, type: String
  field :price_max, type: String
  field :areasquare_min, type: String
  field :areasquare_max, type: String
  field :age_of_building, type: String
  field :minutes_to_take, type: String
  field :floor_plan, type: String

  def area1_config(id=nil)
    unless @area1_config
      @area1_config = YAML.load_file(Rails.root.join('config/pref_areas/pref.yml'))
    end

    if id
      @area1_config[id.to_i]
    else
      @area1_config
    end
  end

  def to_humanize
    ret = []
    valid, _ = check
    return '' if valid == false
    atr = attributes
    ret << area1_name(area1)
    ret << area2_name(area1, area2)
    conf = Settings[atr['site_slug']]
    atr.each do |k,v|
      next unless conf[k]
      ret << conf[k][v]
    end

    ret.join('|')
  end

  def check
    return false, 'site_slug, area1, area2 are should not be nil.' if site_slug.nil? or area1.nil? or area2.nil?
    area2_arr = area2.split(',')
    area2_arr.each do |a|
      return false, 'Array area2 should include area1 code at first 2 chars.' unless area1 == a.slice(0,2)
    end
    return true, nil
  end

  # name_opt: :name | :name_e | :name_h | :name_k
  def area1_name(id, name_opt=nil)
    conf = area1_config(id)
    if name_opt
      conf[name_opt]
    else
      conf[:name]
    end
  end

  def area2_name(id, val)
    a2 = area2_config(id)
    val = val.split(',')
    ret = []
    val.each do |v|
      ret << a2[v.to_s]
    end
    ret.join(',')
  end

  def area2_config(id)
    nm = area1_name(id, :name_e)
    unless @area2_config
      @area2_config = {}
    end
    unless @area2_config[id]
      @area2_config[id] = YAML.load_file(Rails.root.join('config/pref_areas/area_%s.yml' % nm))
    end

    @area2_config[id]
  end

end
