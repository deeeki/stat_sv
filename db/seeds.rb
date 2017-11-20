Clan.delete_all
{
  'ニュートラル' => 0,
  'エルフ' => 1,
  'ロイヤル' => 2,
  'ウィッチ' => 3,
  'ドラゴン' => 4,
  'ネクロマンサー' => 5,
  'ヴァンパイア' => 6,
  'ビショップ' => 7,
}.each do |name, id|
  Clan.create(id: id, name: name)
end

Card.delete_all
YAML.load_file(Rails.root.join('db/seeds/cards.yml')).each do |code, card|
  Card.new(card).tap{|c|
    c.id = c.card_id
    c.code = code
  }.save
end

Archetype.delete_all
YAML.load_file(Rails.root.join('db/seeds/archetypes.yml')).each do |archetype|
  Archetype.create(archetype)
end
