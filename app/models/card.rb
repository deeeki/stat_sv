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
  field :skill, type: String
  field :skill_condition, type: String
  field :skill_target, type: String
  field :skill_option, type: String
  field :skill_preprocess, type: String
  field :skill_disc, type: String
  field :org_skill_disc, type: String
  field :evo_skill_disc, type: String
  field :org_evo_skill_disc, type: String
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
  field :restricted_count, type: Integer
  belongs_to :clan

  class << self
    def alt_codes
      @alt_codes ||= YAML.load_file(Rails.root.join('config/alt_cards.yml'))
    end

    def code_name_index
      @code_name_index ||= Hash[Card.pluck(:code, :card_name)]
    end

    def normalize hash_str
      alt_codes.inject(hash_str){|str, (alt, base)| str.gsub(alt, base) }
    end

    def convert hash_str
      array = hash_str.split('.').reject{|s| s.length != 5 }
      array.inject({}){|deck, card_code| deck[card_code] ||= 0; deck[card_code] += 1; deck }
    end

    def human_convert hash_str
      convert(hash_str).inject({}){|deck, (code, count)| deck[code_name_index[code]] = count; deck }
    end
  end
end
