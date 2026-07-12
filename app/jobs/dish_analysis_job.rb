class DishAnalysisJob < ApplicationJob
  queue_as :default

  def perform(dish_id)
    dish = Dish.find(dish_id)
    return unless dish.image.attached?

    image_bytes = dish.image.download
    mime_type   = dish.image.blob.content_type

    result = ImageAnalysis::GeminiVisionService.call(image_bytes, mime_type)


    if result&.dig("quota_exhausted")
      dish.update(name: "Quota terminé pour aujourd'hui. Réessayez demain")
      source = "quota_exhausted"

    elsif result&.dig("__source") == "no_api_key"
      dish.update(name: "GEMINI_API_KEY non configurée — analyse désactivée")
      source = "no_api_key"

    else
      source = result["__source"]
      result = result.except("__source")


      dish.update(
        name:      result&.dig("name")     || "Analyse impossible",
        calories:  result&.dig("calories") || 0,
        proteins:  result&.dig("proteins") || 0,
        carbs:     result&.dig("carbs")    || 0,
        fats:      result&.dig("fats")     || 0
      )
    end

    Turbo::StreamsChannel.broadcast_replace_to(
      dish,
      target: "analysis-results",
      partial: "dishes/analysis_results",
      locals: { dish: dish, analysis_source: source }
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
