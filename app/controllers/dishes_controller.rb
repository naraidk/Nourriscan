class DishesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_dish, only: [ :show ]

  def new
    @dish = current_user.dishes.build
  end

  def create
    if params[:dish].blank? || params[:dish][:image].blank?
      return render_error("Aucune image fournie.", :bad_request)
    end

    @dish = current_user.dishes.build
    @dish.image.attach(params[:dish][:image])

    if @dish.save
      DishAnalysisJob.perform_later(@dish.id)
      redirect_to @dish, notice: "Analyse en cours…"
    else
      render_error(@dish.errors.full_messages.join(", "), :unprocessable_entity)
    end
  end

  def show
    respond_to do |format|
      format.html
    end
  end

def timer
  @dish = Dish.find(params[:id])

  render turbo_stream: turbo_stream.replace(
    "analysis-timer",
    partial: "dishes/timer",
    locals: { dish: @dish }
  )
end


  private

  def set_dish
    @dish = current_user.dishes.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("Plat introuvable.", :not_found)
  end

  def render_error(message, status)
    respond_to do |format|
      format.html { redirect_to new_dish_path, alert: message }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "flash",
          partial: "shared/flash",
          locals: { alert: message }
        ), status: status
      end
      format.json { render json: { error: message }, status: status }
    end
  end
end
