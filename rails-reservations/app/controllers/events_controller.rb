class EventsController < ApplicationController
  def index
    @events = Event.order(:start_date)
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params)
    if @event.save_with_constraints # pass validate: false to see the constraints in action
      flash[:notice] = "Event created successfully"
      redirect_to events_path
    else
      flash[:error] = "There was a problem creating this event"
      render :new
    end
  end

  def edit
    @event = Event.find(params[:id])
  end

  def update
    @event = Event.find(params[:id]).assign-attributes(event_params)
    if @event.save_with_constraints
      flash[:notice] = "Event updated successfully"
      redirect_to events_path
    else
      flash[:error] = "There was a problem updating this event"
      render :edit
    end
  end

  private

  def event_params
    params.require(:event).permit(
      :name,
      :start_date,
      :end_date,
    )
  end
end
