# frozen_string_literal: true
class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordInvalid, with: :render_new_with_errors
  rescue_from ActionController::ParameterMissing, with: :render_new_with_missing_param

  private

  def render_new_with_errors(exception)
    record = exception.record
    instance_variable_set("@#{record.model_name.singular}", record)
    render :new, status: :unprocessable_content
  end

  def render_new_with_missing_param(exception)
    resource_name = controller_name.singularize
    resource_class = resource_name.classify.constantize
    resource = resource_class.new
    resource.errors.add(exception.param, "is required")
    instance_variable_set("@#{resource_name}", resource)
    render :new, status: :unprocessable_content
  end
end
