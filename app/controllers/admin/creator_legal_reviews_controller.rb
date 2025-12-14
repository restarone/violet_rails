class Admin::CreatorLegalReviewsController < Admin::BaseController
  before_action :load_review, except: [:index, :new, :create, :analytics]

  def index
    @reviews = CreatorLegalReview.order(created_at: :desc)
    @reviews = filter_reviews(@reviews)
    @reviews = @reviews.page(params[:page]).per(20) if @reviews.respond_to?(:page)
  end

  def show
  end

  def new
    @review = CreatorLegalReview.new
  end

  def create
    @review = CreatorLegalReview.new(review_params)

    if params[:document].present?
      @review.original_document.attach(params[:document])
      @review.document_text = extract_document_text(params[:document])
      @review.document_metadata = extract_document_metadata(params[:document])
    end

    if @review.save
      flash.notice = "Legal review created successfully. Ready for analysis."
      redirect_to admin_creator_legal_review_path(@review)
    else
      flash.alert = "Failed to create review: #{@review.errors.full_messages.join(', ')}"
      render :new
    end
  end

  def edit
  end

  def update
    if @review.update(review_params)
      flash.notice = "Legal review updated successfully."
      redirect_to admin_creator_legal_review_path(@review)
    else
      flash.alert = "Failed to update review: #{@review.errors.full_messages.join(', ')}"
      render :edit
    end
  end

  def destroy
    @review.destroy
    flash.notice = "Legal review deleted."
    redirect_to admin_creator_legal_reviews_path
  end

  # Custom actions
  def analyze
    if @review.document_text.blank?
      flash.alert = "Cannot analyze: no document text available."
      redirect_to admin_creator_legal_review_path(@review)
      return
    end

    AnalyzeCreatorLegalReviewJob.perform_later(@review.id)
    flash.notice = "Analysis started. This may take a few minutes."
    redirect_to admin_creator_legal_review_path(@review)
  end

  def approve
    @review.mark_as_completed!
    flash.notice = "Review approved and marked as completed."
    redirect_to admin_creator_legal_review_path(@review)
  end

  def escalate
    reason = params[:reason] || "Escalated by admin for human review"
    @review.mark_as_escalated!(reason)
    flash.notice = "Review escalated for human review."
    redirect_to admin_creator_legal_review_path(@review)
  end

  def add_notes
    if @review.update(reviewer_notes: params[:notes], reviewed_by_user_id: current_user.id, reviewed_at: Time.current)
      flash.notice = "Notes added successfully."
    else
      flash.alert = "Failed to add notes."
    end
    redirect_to admin_creator_legal_review_path(@review)
  end

  def analytics
    @total_reviews = CreatorLegalReview.count
    @reviews_by_domain = CreatorLegalReview.group(:domain_type).count
    @reviews_by_status = CreatorLegalReview.group(:status).count
    @average_risk_by_domain = CreatorLegalReview.average_risk_by_domain
    @escalation_rate = CreatorLegalReview.escalation_rate
    @quality_breakdown = CreatorLegalReview.quality_breakdown
    @recent_reviews = CreatorLegalReview.order(created_at: :desc).limit(10)
  end

  private

  def load_review
    @review = CreatorLegalReview.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash.alert = "Review not found."
    redirect_to admin_creator_legal_reviews_path
  end

  def review_params
    params.require(:creator_legal_review).permit(
      :title,
      :domain_type,
      :creator_email,
      :creator_name,
      :document_text,
      :reviewer_notes,
      creator_context: {}
    )
  end

  def filter_reviews(reviews)
    reviews = reviews.by_domain(params[:domain]) if params[:domain].present?
    reviews = reviews.where(status: params[:status]) if params[:status].present?
    reviews = reviews.needs_review if params[:needs_review] == 'true'
    reviews = reviews.high_risk if params[:high_risk] == 'true'
    reviews
  end

  def extract_document_text(document)
    return nil unless document.present?

    content_type = document.content_type
    tempfile = document.tempfile

    case content_type
    when 'application/pdf'
      extract_pdf_text(tempfile)
    when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      extract_docx_text(tempfile)
    when 'text/plain'
      File.read(tempfile)
    else
      nil
    end
  rescue => e
    Rails.logger.error "Document extraction failed: #{e.message}"
    nil
  end

  def extract_pdf_text(tempfile)
    reader = PDF::Reader.new(tempfile.path)
    reader.pages.map(&:text).join("\n\n")
  rescue => e
    Rails.logger.error "PDF extraction failed: #{e.message}"
    nil
  end

  def extract_docx_text(tempfile)
    doc = Docx::Document.open(tempfile.path)
    doc.paragraphs.map(&:to_s).join("\n\n")
  rescue => e
    Rails.logger.error "DOCX extraction failed: #{e.message}"
    nil
  end

  def extract_document_metadata(document)
    {
      original_filename: document.original_filename,
      content_type: document.content_type,
      size: document.size,
      uploaded_at: Time.current.iso8601
    }
  end
end
