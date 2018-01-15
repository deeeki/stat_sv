class Card
  include Mongoid::Document
  include Mongoid::Timestamps
  field :code, type: String
  field :card_id, type: Integer
  field :foil_card_id, type: Integer
  field :card_set_id, type: Integer
  field :card_name, type: String
  field :is_foil, type: Integer
  field :char_type, type: Integer
  field :tribe_name, type: String
  field :skill_disc, type: String
  field :evo_skill_disc, type: String
  field :cost, type: Integer
  field :atk, type: Integer
  field :life, type: Integer
  field :evo_atk, type: Integer
  field :evo_life, type: Integer
  field :rarity, type: Integer
  field :get_red_ether, type: Integer
  field :use_red_ether, type: Integer
  field :description, type: String
  field :evo_description, type: String
  field :cv, type: String
  field :copyright, type: String
  field :base_card_id, type: Integer
  field :tokens, type: String
  field :normal_card_id, type: Integer
  field :format_type, type: Integer
  belongs_to :clan

  class << self
    def alt_codes
      @alt_codes ||= YAML.load_file(Rails.root.join('config/alt_cards.yml'))
    end
  end
end
