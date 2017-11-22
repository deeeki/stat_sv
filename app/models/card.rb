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
  belongs_to :clan

  ALTERNATIVES = {
    'fof0I' => '61qeS', # エンシェントエルフ
    'fp1Qo' => '62D2o', # 乙姫
    'fpPrI' => '62bTS', # マーリン
    'fpoFo' => '62zty', # フォルテ
    'fqAgI' => '63MII', # ケルベロス
    'fqZ4o' => '63kio', # クイーンヴァンパイア
    'fqxVI' => '6477c', # ジャンヌダルク
    'fsMZQ' => '6KolQ', # 対空射撃
    'fskF2' => '5-Hb2', # タージ
    'fsmhI' => '6LCtI', # ランサー
    'ft9qg' => '6Lc0g', # 精神統一
    'ftZyY' => '62xRs', # アジルス
    'ftahQ' => '6M0tQ', # 誓いの一撃
    'fttUY' => '6MJgY', # セイバーオルタ
    'fuJ4A' => '6MlGA', # 絡みつく鎖
    'fuglo' => '6N6y6', # バーサーカー
    'fwHII' => '6DH3S', # 深き森の異形
    'fwfio' => '69rKo', # アルベール
    'fx27I' => '6E1uS', # 魔導の巨兵
    'fxQXo' => '6EQIo', # 水竜神の巫女
    'fxoyI' => '6A-aI', # ネフティス
    'fyBMo' => '6FB7o', # ベルフェゴール
    'fyZnI' => '6FZYS', # イージス
    'f-sGI' => '6ADlI', # ドロシー
    'f_Ego' => '6Ac9o', # インペリアルドラグーン
  }
end
