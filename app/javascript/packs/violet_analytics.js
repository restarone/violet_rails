const VIOLET_EVENT_CATEGORIES = {
    page_visit: 'page_visit',
    click: 'click',
    form_submit: 'form_submit',
    video_view: 'video_view',
    section_view: 'section_view',
}
var analyticsLoaded = false;


$(window).on("load turbo:load", () => {
    if (analyticsLoaded) { return ; }

    const pageId = $('body').data('page-id');
    const analyticsBrowserStorageKey = `violet_analytics_page_${pageId}`;

    let sectionsViewedMap = {};

    $('[data-violet-track-section-view="true"]').each(function() {
        sectionsViewedMap[this.dataset.violetEventName] = false;
    })

    sessionStorage.setItem(analyticsBrowserStorageKey, JSON.stringify({sectionsViewedMap}));
 
    $('[data-violet-track-click="true"]').on('click', function() {
        const eventName = this.dataset.violetEventName || VIOLET_EVENT_CATEGORIES.click;
        const eventLabel = this.dataset.violetEventLabel || eventName;
        ahoy.track(eventName, {
            category: VIOLET_EVENT_CATEGORIES.click,
            label: eventLabel,
            page_id: pageId,
            tag: this.tagName,
            href: this.href
        })
    })

    // Usage: {{ cms:helper render_form, 1, { data: { violet-track-form-submit: true, violet-event-name: 'contact_form_submit', violet-event-label: 'Contact form Submission' } } }}
    $('[data-violet-track-form-submit="true"]').on('submit', function() {
        const eventName = this.dataset.violetEventName || `${this.dataset.slug}-form-submit`;
        const eventLabel = this.dataset.violetEventLabel || `${this.dataset.slug} Form`;
        ahoy.track(eventName, {
            category: VIOLET_EVENT_CATEGORIES.form_submit,
            label: eventLabel,
            page_id: pageId,
        })
    })

    // Usage:
    // <video data-violet-track-video-view="true" data-violet-resource-id="<%= resource.id %>" data-violet-event-name="intro_video_watch" data-violet-event-label="Intro Video" width="500px"  controls>
    //   <source src="<%= resource.props['demo'].file_url %>" type="video/mp4">
    // </video>
    $('[data-violet-track-video-view="true"]').each( function() {
        var startTime;
        const eventName = this.dataset.violetEventName || VIOLET_EVENT_CATEGORIES.video_view;
        const eventLabel = this.dataset.violetEventLabel || eventName;
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
                category: VIOLET_EVENT_CATEGORIES.video_view,
                label: eventLabel,
                page_id: pageId,
                resource_id: resourceId,
                video_start: isFirstPlay,
                watch_time: watchTime,
                total_duration: this.duration * 1000
            })

            // replay counts as a new view event
            isFirstPlay = e.type == 'ended'
        });
    })

    // track section views
    $('[data-violet-track-section-view="true"]').each(function() {
        trackSectionViews(this, pageId)
    })

    analyticsLoaded = true;
})

$(window).on('beforeunload turbo:before-visit', function() {
    // trigger pause event on videos
    $('[data-violet-track-video-view="true"]').each( function() { this.pause(); })
    analyticsLoaded = false;
})

function trackSectionViews(target, pageId) {
    const eventName = target.dataset.violetEventName;
    const observerOptions = { root: null, threshold: target.dataset.violetVisibilityThreshold || 0.75 };
    const analyticsBrowserStorageKey = `violet_analytics_page_${pageId}`  

    const observer = new IntersectionObserver((entries) => {
        const analyticsStorage = JSON.parse(sessionStorage.getItem(analyticsBrowserStorageKey));
        const entry = entries[0];
        const targetHasBeenViewed = analyticsStorage.sectionsViewedMap[eventName];
        if (entry.isIntersecting && !targetHasBeenViewed) {
            ahoy.track(eventName, {
                category: VIOLET_EVENT_CATEGORIES.section_view,
                label: target.dataset.violetEventLabel || eventName,
                page_id: pageId
            });
            analyticsStorage.sectionsViewedMap[eventName] = true;
            sessionStorage.setItem(analyticsBrowserStorageKey, JSON.stringify(analyticsStorage));
        }
    }, observerOptions);

    observer.observe(target);
}