# frozen_string_literal: true

class HospitalsController < ApplicationController
  load_and_authorize_resource
  before_action :set_hospital, only: %i[show destroy update]

  def new
    @hospital = Hospital.new
  end

  def create
    hospital = Hospital.new(hospital_params.merge(user: current_user))

    if hospital.save
      redirect_to hospital_path(hospital), flash: { success: "Hospital created." }
    else
      redirect_to hospitals_path, flash: { error: "Failed to create new hospital: #{hospital.errors.full_messages.to_sentence}" }
    end
  end

  def index
    @hospitals = Hospital.all.page params[:page]
  end

  def show
  end

  def update
    if @hospital.update(hospital_params)
      redirect_to hospital_path(@hospital), flash: { success: "Hospital updated." }
    else
      redirect_to hospital_path(@hospital), flash: { error: "Failed to update hospital: #{@hospital.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @hospital.destroy
    redirect_to hospitals_path, flash: { success: "Hospital deleted." }
  end

  private

  def hospital_params
    params.require(:hospital).permit(:name, :status, :notes, :user_id, :street, :city, :province, :postal_code, :country, :warehouse_id)
  end

  def set_hospital
    @hospital = Hospital.find(params[:id])
  end
end
