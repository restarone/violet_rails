class AnalyzeCreatorLegalReviewJob < ApplicationJob
  queue_as :default

  def perform(review_id)
    review = CreatorLegalReview.find(review_id)
    service = CreatorLegalReviewService.new(review)
    result = service.analyze!

    if result[:success]
      Rails.logger.info "CreatorLegalReview #{review_id} analyzed successfully"
    else
      Rails.logger.error "CreatorLegalReview #{review_id} analysis failed: #{result[:error]}"
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "CreatorLegalReview #{review_id} not found"
  rescue => e
    Rails.logger.error "CreatorLegalReview #{review_id} job failed: #{e.message}"
    raise # Re-raise for job retry mechanism
  end
end
