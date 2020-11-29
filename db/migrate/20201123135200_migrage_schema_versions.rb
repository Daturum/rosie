class MigrageSchemaVersions < ActiveRecord::Migration[5.2]
  VERSIONS_MIGRATION = [
    {from: '20180720190700', to: '20201123135201'},
    {from: '20180425205058', to: '20201123135202'},
    {from: '20180425201405', to: '20201123135203'},
    {from: '20180425225051', to: '20201123135204'},
    {from: '20180426084958', to: '20201123135205'},
    {from: '20180426101535', to: '20201123135206'},
    {from: '20180513202631', to: '20201123135207'},
    {from: '20180720190800', to: '20201123135208'},
    {from: '20200307185350', to: '20201123135209'},
    {from: '20200310185741', to: '20201123135210'},
    {from: '20200329105549', to: '20201123135211'},
  ]

  VERSIONS_REMOVE = ['']

  def up
    VERSIONS_MIGRATION.each do |version_migration|
      sql = "UPDATE schema_migrations SET version='#{version_migration[:to]}' WHERE version='#{version_migration[:from]}'"
      execute(sql)
    end
  end

  def down
    VERSIONS_MIGRATION.each do |version_migration|
      sql = "UPDATE schema_migrations SET version='#{version_migration[:from]}' WHERE version='#{version_migration[:to]}'"
      execute(sql)
    end
  end
end
