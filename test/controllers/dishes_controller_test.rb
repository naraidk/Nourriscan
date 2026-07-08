require "test_helper"

class DishesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    sign_in users(:one)
    get new_dish_path
    assert_response :success
  end

  test "new form disables turbo for standard HTML submission" do
    sign_in users(:one)
    get new_dish_path
    assert_select "form[data-turbo='false']"
  end

  test "show renders html for browser requests" do
    sign_in users(:one)
    dish = dishes(:one)
    get dish_path(dish)
    assert_response :success
    assert_select "#dish-title"
  end
end
