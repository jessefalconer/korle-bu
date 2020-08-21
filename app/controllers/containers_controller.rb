# frozen_string_literal: true

class ContainersController < ApplicationController
  before_action :set_container, only: %i[show destroy edit update]

  def list
    @containers = Container.all.page params[:page]
  end

  def new
    @container = Container.new
  end

  def create
    Container.create(container_params.merge(user: current_user))
    redirect_to containers_path
  end

  def index
    @containers = Container.all.page params[:page]
  end

  def show
  end

  def edit
  end

  def update
    @container.update(container_params)
    redirect_to container_path(@container)
  end

  def destroy
    @container.destroy
    redirect_to containers_path
  end

  private

  def container_params
    params.require(:container).permit(:name, :status, :notes)
  end

  def set_container
    @container = Container.find(params[:id])
  end
end
