class AddAnalysisStartedAtToDishes < ActiveRecord::Migration[8.1]
  def change
    add_column :dishes, :analysis_started_at, :datetime
  end
end
