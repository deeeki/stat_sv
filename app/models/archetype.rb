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

  class << self
    def detect hash_str
      clan_id, deck = convert(normalize(hash_str.split('/').last))
      where(clan_id: clan_id).order_by(detection_order: :asc).entries.find do |archetype|
        archetype.match?(deck)
      end
    end

    def normalize hash_str
      Card.alt_codes.inject(hash_str){|str, (alt, base)| str.gsub(alt, base) }
    end

    private

    def convert hash_str
      array = hash_str.split('.')
      [array[1].to_i, array.drop(2).inject({}){|deck, card_code| deck[card_code] ||= 0; deck[card_code] += 1; deck }]
    end
  end

  def match? deck
    conditions.each do |condition|
      return true if condition.map{|card_code, count| deck[card_code] && deck[card_code] >= count }.all?
    end
    false
  end
end
