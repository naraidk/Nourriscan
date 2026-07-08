require "test_helper"

class GeminiVisionServiceTest < ActiveSupport::TestCase
  setup do
    @service = ImageAnalysis::GeminiVisionService
  end

  test "parse_response extracts JSON correctly" do
    response_text = '{"name": "Spaghetti Bolognese", "calories": 450, "proteins": 15, "carbs": 55, "fats": 18}'
    result = @service.parse_response(response_text)

    assert_equal "Spaghetti Bolognese", result["name"]
    assert_equal 450, result["calories"]
    assert_equal 15, result["proteins"]
    assert_equal 55, result["carbs"]
    assert_equal 18, result["fats"]
  end

  test "parse_response handles markdown wrapped JSON" do
    response_text = "```json\n{\"name\": \"Pizza\", \"calories\": 300, \"proteins\": 12, \"carbs\": 40, \"fats\": 10}\n```"
    result = @service.parse_response(response_text)

    assert_equal "Pizza", result["name"]
    assert_equal 300, result["calories"]
  end

  test "parse_response provides defaults for missing fields" do
    response_text = '{"name": "Unknown Dish"}'
    result = @service.parse_response(response_text)

    assert_equal "Unknown Dish", result["name"]
    assert_equal 0, result["calories"]
    assert_equal 0, result["proteins"]
    assert_equal 0, result["carbs"]
    assert_equal 0, result["fats"]
  end

  test "parse_response converts string numbers to integers" do
    response_text = '{"name": "Salad", "calories": "250", "proteins": "8", "carbs": "30", "fats": "12"}'
    result = @service.parse_response(response_text)

    assert_equal 250, result["calories"]
    assert_equal 8, result["proteins"]
    assert_kind_of Integer, result["calories"]
  end

  test "detect_mime_type returns correct type for common formats" do
    assert_equal "image/png", @service.detect_mime_type("https://example.com/image.png")
    assert_equal "image/jpeg", @service.detect_mime_type("https://example.com/image.jpg")
    assert_equal "image/jpeg", @service.detect_mime_type("https://example.com/image.jpeg")
    assert_equal "image/webp", @service.detect_mime_type("https://example.com/image.webp")
    assert_equal "image/gif", @service.detect_mime_type("https://example.com/image.gif")
  end

  test "returns mock data when API key is not set" do
    original_key = ENV["GEMINI_API_KEY"]
    ENV["GEMINI_API_KEY"] = ""

    # Reload the constant
    ImageAnalysis::GeminiVisionService.const_set(:API_KEY, "")

    result = @service.call("https://example.com/food.jpg")

    assert result["name"].present?
    assert result["calories"].is_a?(Integer)

    # Restore
    ENV["GEMINI_API_KEY"] = original_key
  end
end
