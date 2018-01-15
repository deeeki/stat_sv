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
  'ネメシス' => 8,
}.each do |name, id|
  Clan.create(id: id, name: name)
end

Archetype.delete_all
%w[u r].each do |format|
  YAML.load_file(Rails.root.join("db/seeds/#{format}_archetypes.yml")).each do |archetype|
    Archetype.create(archetype)
  end
end
