class Territory < ActiveRecord::Base
  belongs_to :owner, class_name: "User"
  has_many :detections
  has_many :locations, :through => :detections
  has_many :invasions
  has_many :invaders, class_name: User, through: :invasions, source: :user
  scope :actives, conditions: {expired_time: nil}

  def expire
    self.expired_time = DateTime.now
  end

  def add_location(loc)
    locations << loc if self.include? loc
  end

  def include?(loc)
    dist = distance(loc)
    dist < self.radius
  end

  def distance(loc)
    y1 = self.latitude * Math::PI / 180
    x1 = self.longitude * Math::PI / 180
    y2 = loc.latitude * Math::PI / 180
    x2 = loc.longitude * Math::PI / 180
    earth_r = 6378140
    deg = Math::sin(y1) * Math::sin(y2) + Math::cos(y1) * Math::cos(y2) * Math::cos(x2 - x1)
    distance = earth_r * (Math::atan(-deg / Math::sqrt(-deg * deg + 1)) + Math::PI / 2)
    return distance
  end

  def to_hash
    hash = Hash[self.attributes]
    hash[:territory_id] = self.id
    hash.delete "id"
    hash
  end
end
