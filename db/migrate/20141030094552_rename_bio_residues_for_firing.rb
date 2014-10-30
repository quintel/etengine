class RenameBioResiduesForFiring < ActiveRecord::Migration
  def up
    update_query_table_cells('bio_residues_for_firing', 'woody_biomass')
  end

  def down
    update_query_table_cells('woody_biomass', 'bio_residues_for_firing')
  end

  def update_query_table_cells(from, to)
    from_re = /#{ Regexp.escape(from) }/

    QueryTableCell.find_each do |qtc|
      qtc.name = to if qtc.name && qtc.name == from

      if qtc.gquery && qtc.gquery.include?(from)
        qtc.gquery = qtc.gquery.gsub(from_re, to)
      end

      qtc.save(validate: false) if qtc.changed?
    end
  end
end
