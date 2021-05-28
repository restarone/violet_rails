class Comfy::Admin::CallToActionsController < Comfy::Admin::Cms::BaseController
  before_action :ensure_authority_to_manage_web
  before_action :set_call_to_action, only: %i[ show edit update destroy ]

  # GET /call_to_actions or /call_to_actions.json
  def index
    params[:q] ||= {}
    @call_to_actions_q = CallToAction.ransack(params[:q])
    @call_to_actions = @call_to_actions_q.result.paginate(page: params[:page], per_page: 10)
  end

  # GET /call_to_actions/1 or /call_to_actions/1.json
  def show
    params[:q] ||= {}
    @call_to_action_responses_q = @call_to_action_responses.ransack(params[:q])
    @call_to_action_responses = @call_to_action_responses_q.result.paginate(page: params[:page], per_page: 10)
  end

  # GET /call_to_actions/new
  def new
    @call_to_action = CallToAction.new
  end

  # GET /call_to_actions/1/edit
  def edit
  end

  # POST /call_to_actions or /call_to_actions.json
  def create
    @call_to_action = CallToAction.new(call_to_action_params)

    respond_to do |format|
      if @call_to_action.save
        format.html { redirect_to @call_to_action, notice: "Call to action was successfully created." }
        format.json { render :show, status: :created, location: @call_to_action }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @call_to_action.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /call_to_actions/1 or /call_to_actions/1.json
  def update
    respond_to do |format|
      if @call_to_action.update(call_to_action_params)
        format.html { redirect_to @call_to_action, notice: "Call to action was successfully updated." }
        format.json { render :show, status: :ok, location: @call_to_action }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @call_to_action.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /call_to_actions/1 or /call_to_actions/1.json
  def destroy
    @call_to_action.destroy
    respond_to do |format|
      format.html { redirect_to call_to_actions_url, notice: "Call to action was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_call_to_action
      @call_to_action = CallToAction.find(params[:id])
      @call_to_action_responses = @call_to_action.call_to_action_responses
    end

    # Only allow a list of trusted parameters through.
    def call_to_action_params
      params.require(:call_to_action).permit(
        :title, 
        :cta_type,
        :success_message,
        :failure_message,
        :name_label,
        :name_placeholder,
        :phone_placeholder,
        :phone_label,
        :message_label,
        :message_placeholder,
        :email_label,
        :email_placeholder,
        :submit_button_label
      )
    end
end
