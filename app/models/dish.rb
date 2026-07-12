class Dish < ApplicationRecord
  before_create :set_analysis_started_at
  belongs_to :user
  has_one_attached :image

  validates :user, presence: true
  def set_analysis_started_at
    self.analysis_started_at = Time.current
  end
end