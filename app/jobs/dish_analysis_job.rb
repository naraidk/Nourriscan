class DishAnalysisJob < ApplicationJob
  queue_as :default

  def perform(dish_id)
    dish = Dish.find(dish_id)
    return unless dish.image.attached?

    image_url = Rails.application.routes.url_helpers.rails_blob_url(
      dish.image,
      host: Rails.application.routes.default_url_options[:host]
    )

    result = ImageAnalysis::GeminiVisionService.call(image_url)

    dish.update(
      name:      result["name"]      || "Analyse impossible",
      calories:  result["calories"]  || 0,
      proteins:  result["proteins"]  || 0,
      carbs:     result["carbs"]     || 0,
      fats:      result["fats"]      || 0
    )

    # ⭐ THIS IS WHERE YOU ADD THE BROADCAST
    Turbo::StreamsChannel.broadcast_replace_to(
      dish,
      target: "analysis-results",
      partial: "dishes/analysis_results",
      locals: { dish: dish }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      dish,
      target: "dish-title",
      partial: "dishes/title",
      locals: { dish: dish }
    )

  rescue => e
    Rails.logger.error("DishAnalysisJob error: #{e.class}: #{e.message}")
    dish.update(name: "Analyse impossible") if dish
  end
end
