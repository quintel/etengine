class CreateEnergyBalanceGroups < ActiveRecord::Migration
  def self.up
    create_table :energy_balance_groups do |t|
      t.string :name

      t.timestamps
    end
    
    items = {
      5 =>  'before savings',
      6 =>  'savings',
      7 =>  'useful consumption',
      8 =>  'preferred technologies',
      9 =>  'technology groups',
      11 => 'technologies',
      12 => 'local mixer',
      13 => 'application',
      14 => 'final consumption',
      15 => 'locally available',
      16 => 'local heat generation',
      17 => 'local CHPs',
      18 => 'local power generation',
      19 => 'subdistribution 3',
      20 => 'subdistribution 2',
      21 => 'subdistribution 1',
      22 => 'distribution',
      23 => 'refinery',
      24 => 'central heat generation',
      25 => 'central CHPs',
      26 => 'central power generation',
      27 => 'carrier mixing',
      28 => 'distribution primary carriers',
      29 => 'treatment',
      30 => 'storage',
      31 => 'primary consumption',
      32 => 'export',
      33 => 'growth and production',
      34 => 'extraction',
      35 => 'import',
      36 => 'foreign production',
      37 => 'environment'
    }
    
    items.each_pair do |id, name|
      e      = EnergyBalanceGroup.new
      e.id   = id.to_i
      e.name = name
      e.save!
    end
    
    
    add_column :converters, :energy_balance_group_id, :integer
    Converter.reset_column_information
    Converter.find_each do |c|
      id = c.energy_balance_group
      next if id.nil?
      c.energy_balance_group_id = id.to_i
      c.save
    end
    remove_column :converters, :energy_balance_group
    
  end

  def self.down
    drop_table :energy_balance_groups
    add_column :converters, :energy_balance_group, :string
    Converter.reset_column_information
    Converter.find_each do |c|
      c.energy_balance_group = c.energy_balance_group_id.to_s
      c.save
    end    
    remove_column :converters, :energy_balance_group_id
  end
end
