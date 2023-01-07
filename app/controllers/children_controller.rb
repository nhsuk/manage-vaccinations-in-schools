class ChildrenController < ApplicationController
  before_action :set_child, only: %i[ show edit update destroy ]

  # GET /children
  def index
    @children = Child.all
  end

  # GET /children/1
  def show
  end

  # GET /children/new
  def new
    @child = Child.new
  end

  # GET /children/1/edit
  def edit
  end

  # POST /children
  def create
    @child = Child.new(child_params)

    if @child.save
      redirect_to @child, notice: "Child was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /children/1
  def update
    if @child.update(child_params)
      redirect_to @child, notice: "Child was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /children/1
  def destroy
    @child.destroy
    redirect_to children_url, notice: "Child was successfully destroyed."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_child
      @child = Child.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def child_params
      params.fetch(:child, {})
    end
end
