require 'securerandom'

class User < ActiveRecord::Base
  before_create :generate_token
  has_many :locations, dependent: :destroy
  has_many :my_territories, class_name: "Territory", foreign_key: 'owner_id', dependent: :destroy
  has_many :invasions, dependent: :destroy
  has_many :enemy_territories, class_name: "Territory", through: :invasions, source: :territory
  has_many :notifications, dependent: :destroy
  MINIMUM_TIME_INTERVAL = 300

  def valid_territories
    my_territories.where :expired_time => nil
  end

  def generate_token
    token = SecureRandom.base64(16)
    self.token = token
  end

  def add_territory(latitude, longitude, character_id)
    character = Character.find(character_id)
    return unless character
    return if character.cost > self.gps_point

    ter = Territory.new(latitude: latitude, longitude: longitude, character: character, owner: self)
    self.gps_point -= character.cost
    ter if self.save and ter.save
  end

  def add_location(latitude, longitude)
    recent_location = Location.order(created_at: :desc).first
    time_interval = (recent_location != nil)? Time.now - recent_location.created_at : nil
    return if time_interval != nil and time_interval < MINIMUM_TIME_INTERVAL

    loc = Location.new(latitude: latitude, longitude: longitude){|loc|
      loc.user = self
    }

    self.gps_point += 1 if self.gps_point < self.gps_point_limit
    self.save
    loc
  end

  def supply(ter, point)
    return "error" if point > self.gps_point
    self.gps_point -= point
    ter.supply(point) and self.save
  end

  def to_hash
    hash = Hash[self.attributes]
    hash["user_id"] = self.id
    hash.delete "id"
    hash
  end
end
