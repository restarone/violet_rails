class MeetingsController < Comfy::Admin::Cms::BaseController
  before_action :set_meeting, only: %i[ show edit update destroy ]

  # GET /meetings or /meetings.json
  def index
    @meetings = Meeting.all
  end

  # GET /meetings/1 or /meetings/1.json
  def show
  end

  # GET /meetings/new
  def new
    @meeting = Meeting.new
  end

  # GET /meetings/1/edit
  def edit
  end

  # POST /meetings or /meetings.json
  def create
    @meeting = Meeting.new(meeting_params)
    @meeting.external_meeting_id = "VioletRails@#{SecureRandom.uuid}"
    @meeting.status = 'CONFIRMED'
    @meeting.participant_emails = meeting_params[:participant_emails].filter{ |node| URI::MailTo::EMAIL_REGEXP.match?(node) }
  
    respond_to do |format|
      if @meeting.save
        # send .ics file to participants
        cal = Icalendar::Calendar.new
        filename = "Invitation: #{@meeting.name}"
        # to generate outlook
        if false == 'vcs'
          cal.prodid = '-//Microsoft Corporation//Outlook MIMEDIR//EN'
          cal.version = '1.0'
          filename += '.vcs'
        else # ical
          cal.prodid = '-//Restarone Solutions, Inc.//NONSGML ExportToCalendar//EN'
          cal.version = '2.0'
          filename += '.ics'
        end
        
        cal.event do |e|
          e.dtstart     = Icalendar::Values::DateTime.new(@meeting.start_time, tzid: @meeting.timezone)
          e.dtend       = Icalendar::Values::DateTime.new(@meeting.end_time, tzid: @meeting.timezone)
          e.summary     = @meeting.name
          e.description = @meeting.description
          # e.url         = event_url(foo)
          e.location    = @meeting.location
          e.attendee = @meeting.participant_emails
        end
        file = cal.to_ical
        attachment = { filename: filename, mime_type: "text/calendar", content: file }
        blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new(attachment[:content]), filename: attachment[:filename], content_type: attachment[:mime_type], metadata: nil)
        email_thread = MessageThread.create!(recipients: @meeting.participant_emails, subject: "Invitation: #{@meeting.name}")
        email_content = <<-HTML
        <div>
          <p>You have been invited to the following meeting, please see details below<br><br>
          </p>

        </div>
        HTML
        email_content += ActionText::Content.new("<action-text-attachment sgid='#{blob.attachable_sgid}'></action-text-attachment>").to_s
        email_message = email_thread.messages.create!(
          content: email_content.html_safe,
          from: "#{Apartment::Tenant.current}@#{ENV['APP_HOST']}"
        )
        EMailer.with(message: email_message, message_thread: email_thread, attachments: [attachment]).ship.deliver_later

        format.html { redirect_to @meeting, notice: "Meeting was successfully created." }
        format.json { render :show, status: :created, location: @meeting }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @meeting.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /meetings/1 or /meetings/1.json
  def update
    respond_to do |format|
      if @meeting.update(meeting_params)
        format.html { redirect_to @meeting, notice: "Meeting was successfully updated." }
        format.json { render :show, status: :ok, location: @meeting }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @meeting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /meetings/1 or /meetings/1.json
  def destroy
    @meeting.destroy
    respond_to do |format|
      format.html { redirect_to meetings_url, notice: "Meeting was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_meeting
      @meeting = Meeting.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def meeting_params
      params.require(:meeting).permit(:name, :start_time, :end_time, :description, :timezone, :location, participant_emails: [])
    end
end
