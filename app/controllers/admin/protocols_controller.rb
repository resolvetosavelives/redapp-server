class Admin::ProtocolsController < AdminController
  before_action :set_protocol, only: %i[show edit update destroy]

  def index
    authorize Protocol
    @protocols = policy_scope(Protocol).order(:name)
  end

  def show
    @protocol_drugs = @protocol.protocol_drugs.order(:name)
  end

  def new
    @protocol = Protocol.new
    authorize @protocol
  end

  def edit
  end

  def create
    @protocol = Protocol.new(protocol_params)
    authorize @protocol

    if @protocol.save
      redirect_to [:admin, @protocol], notice: 'Protocol was successfully created.'
    else
      render :new
    end
  end

  def update
    if @protocol.update(protocol_params)
      redirect_to [:admin, @protocol], notice: 'Protocol was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @protocol.destroy
    redirect_to admin_protocols_url, notice: 'Protocol was successfully deleted.'
  end

  private

  def set_protocol
    @protocol = Protocol.find(params[:id])
    authorize @protocol
  end

  def protocol_params
    params.require(:protocol).permit(:name, :follow_up_days)
  end
end
