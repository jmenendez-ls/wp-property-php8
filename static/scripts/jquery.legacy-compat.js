/**
 * Restores jQuery 1.x properties removed in jQuery 3.
 * Required by bundled legacy scripts (jquery.address, jquery.scrollTo, etc.).
 */
(function ($) {
	var ua = navigator.userAgent;

	if (!$.support) {
		$.support = { opacity: true };
	} else if (typeof $.support.opacity === 'undefined') {
		$.support.opacity = true;
	}

	if (!$.browser) {
		$.browser = {};
	}

	if (typeof $.browser.safari === 'undefined') {
		$.browser.safari = /safari/i.test(ua) && !/chrome|chromium|android/i.test(ua);
	}

	if (typeof $.browser.msie === 'undefined') {
		$.browser.msie = /msie|trident/i.test(ua);
	}

	if (typeof $.browser.version === 'undefined') {
		$.browser.version = '0';
	}
})(jQuery);
