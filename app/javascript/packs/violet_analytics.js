$(document).on("turbo:load", () => {
    $('body[data-violet-track-page-visit="true"]').on('load', function() {
        const eventName = this.dataset.violetEventName || 'page_view';
        const eventLabel = this.dataset.violetEventLabel;
        ahoy.track(eventName, {
            category: 'page_visit',
            label: eventLabel,
            page_id: $('body').data('page-id'),
            page_title: document.title
        })
    })

    $('[data-violet-track-click="true"]').on('click', function() {
        const eventName = this.dataset.violetEventName || 'click';
        const eventLabel = this.dataset.violetEventLabel;
        ahoy.track(eventName, {
            category: 'click',
            label: eventLabel,
            page_id: $('body').data('page-id'),
            tag: this.tagName,
            href: this.href
        })
    })

    // Usage: {{ cms:helper render_form, 1, { data: { violet-track-form-submit: true, violet-event-name: 'contact_form_submit', violet-event-label: 'Contact form Submission' } } }}
    $('[data-violet-track-form-submit="true"]').on('submit', function() {
        const eventName = this.dataset.violetEventName;
        const eventLabel = this.dataset.violetEventLabel;
        ahoy.track(eventName, {
            category: 'form_submit',
            label: eventLabel,
            page_id: $('body').data('page-id'),
        })
    })

    // Usage:
    // <video data-violet-track-video-view="true" data-violet-resource-id="<%= resource.id %>" data-violet-event-name="intro_video_watch" data-violet-event-label="Intro Video" width="500px"  controls>
    //   <source src="<%= resource.props['demo'].file_url %>" type="video/mp4">
    // </video>
    $('[data-violet-track-video-view="true"]').each( function(index) {

        var startTime;
        const eventName = this.dataset.violetEventName;
        const eventLabel = this.dataset.violetEventLabel;
        var resourceId = this.dataset.violetResourceId;
        // Count paused and then played video as a single view.
        var isFirstPlay = true;

        $(this).on("play", function() {
            if (this.seeking) { return; }
            startTime = Date.now();
        });

        $(this).on("pause ended", function(e) {
            if (this.seeking) { return; }
            var watchTime = Date.now() - startTime;
            ahoy.track(eventName, {
                category: 'video_view',
                label: eventLabel,
                page_id: $('body').data('page-id'),
                watch_time: watchTime,
                resource_id: resourceId,
                is_first_play: isFirstPlay
            })

            // replay counts as a new view event
            isFirstPlay = e.type == 'ended'
        });
    })
})