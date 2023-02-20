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
      path = params[:redirect].presence || hospital_path(hospital)
      redirect_to path, flash: { success: "Hospital, Facility or Clinic created." }
    else
      path = params[:redirect].presence || hospitals_path
      redirect_to path, flash: { error: "Failed to create new hospital: #{hospital.errors.full_messages.to_sentence}" }
    end
  end

  def index
    @hospitals = Hospital.accessible_by(current_ability).page params[:page]
  end

  def show
    @unpacking_vents = @hospital
      .unpacking_events
      .order(:created_at)
      .reverse_order
      .accessible_by(current_ability).page params[:page]
  end

  def update
    if @hospital.update(hospital_params)
      redirect_to hospital_path(@hospital), flash: { success: "Hospital, Facility or Clinic updated." }
    else
      redirect_to hospital_path(@hospital), flash: { error: "Failed to update hospital: #{@hospital.errors.full_messages.to_sentence}" }
    end
  end

  def destroy
    @hospital.destroy
    redirect_to hospitals_path, flash: { success: "Hospital, Facility or Clinic deleted." }
  end

  private

  def hospital_params
    params.require(:hospital)
      .permit(
        :name, :status, :notes, :user_id, :street, :city, :province,
        :postal_code, :country, :phone, :warehouse_id, :longitude,
        :latitude, :point_of_contact_name, :point_of_contact_phone
      )
  end

  def set_hospital
    @hospital = Hospital.find(params[:id])
  end
end
