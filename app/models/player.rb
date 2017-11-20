class Player
  include Mongoid::Document
  include Mongoid::Timestamps
  field :player_id, type: Integer
  field :name, type: String
  field :group, type: String
  field :rank, type: Integer
  field :deck_url1, type: String
  field :deck_url2, type: String
  belongs_to :tournament
  belongs_to :archetype1, class_name: 'Archetype'
  belongs_to :archetype2, class_name: 'Archetype'

  def archetypes
    [archetype1, archetype2].compact
  end
end
