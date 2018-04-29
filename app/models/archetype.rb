class Archetype
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Enumerize
  field :name, type: String
  field :format, type: String
  field :detection_order, type: Integer
  field :conditions, type: Array
  enumerize :format, in: [:rotation, :unlimited], default: :rotation, scope: true
  belongs_to :clan
  belongs_to :period

  class << self
    def detect hash_str, format = :rotation, period = Period.current
      normalized = Card.normalize(hash_str.split('/').last)
      clan_id = normalized[2].to_i
      deck = Card.convert(normalized)
      with_format(format).where(clan_id: clan_id, period_id: period.id).order_by(detection_order: :asc).entries.find do |archetype|
        archetype.match?(deck)
      end
    end
  end

  def match? deck
    conditions.each do |condition|
      return true if condition.map{|card_code, count| deck[card_code] && deck[card_code] >= count }.all?
    end
    false
  end
end
