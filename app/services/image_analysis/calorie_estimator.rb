module ImageAnalysis
  class CalorieEstimator
    def self.call(image_url)
      {
        "name" => "Plat détecté (mock)",
        "calories" => rand(300..900),
        "proteins" => rand(10..40),
        "carbs" => rand(20..80),
        "fats" => rand(10..30)
      }
    end
  end
end
