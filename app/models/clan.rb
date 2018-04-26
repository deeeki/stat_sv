class Clan
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  has_many :cards

  class << self
    def detect hash_str
      clan_id = hash_str.split('/').last.split('.').second.to_i
      Clan.find_by(id: clan_id)
    end
  end
end
