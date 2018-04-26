class Player
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String
  field :group, type: String
  field :rank, type: Integer
  field :deck_url1, type: String
  field :deck_url2, type: String
  belongs_to :user
  belongs_to :tournament
  belongs_to :archetype1, class_name: 'Archetype', optional: true
  belongs_to :archetype2, class_name: 'Archetype', optional: true

  def clans
    @clans ||= if archetypes.present?
                 archetypes.map(&:clan)
               elsif deck_url1 && deck_url2
                 [Clan.detect(deck_url1), Clan.detect(deck_url2)].compact
               end
  end

  def archetypes
    [archetype1, archetype2].compact
  end
end
