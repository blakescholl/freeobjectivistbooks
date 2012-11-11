(function ($) {
    $.fn.handleAjax = function (handler) {
    	return this.on({
            "ajax:beforeSend" : function () {
                $(this).find('.loading').spin('medium', '#666');
            },
            "ajax:complete" : function () {
                $(this).find('.loading').spin(false);
            },
            "ajax:success" : handler,
            "ajax:error" : function (event, request, status, error) {
                var message = 'Sorry, we hit an unexpected error. Try again or email me at jason@rationalegoist.com for help.';
                if (request.getResponseHeader("Content-Type").match("application/json")) {
                    response = JSON.parse(request.responseText);
                    if (response.message) {
                        message = response.message;
                    }
                }
                alert(message);
            }
        });
    };

    $.fn.fadeAndSlideIn = function (duration) {
        return this.filter(':not(:visible)').fadeAndSlide(duration, 'show');
    };

    $.fn.fadeAndSlideOut = function (duration) {
        return this.filter(':visible').fadeAndSlide(duration, 'hide');
    };

    $.fn.fadeAndSlide = function (duration, direction) {
        if (!duration && duration !== 0) duration = 600;
		var direction = direction || 'toggle';
		var animation = {height: direction, opacity: direction, 'padding-top': direction, 'padding-bottom': direction};
        return this.animate(animation, {duration: duration});
    };
})(jQuery);
