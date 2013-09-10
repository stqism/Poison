(function() {
    window.preHeight = 0;
    window.__SCPostMessageArray = function(m) {
        var body = document.body;
        var html = document.documentElement;
        var h = Math.max(body.scrollHeight, body.offsetHeight,
                         html.clientHeight, html.scrollHeight, html.offsetHeight);
        window.preHeight = h;
        for (var i = 0; i < m.length; i++) {
            pushMessage(m[i]);
        }
        window.__SCScrollViewToBottomIfRequired();
    }
    window.__SCPostMessage = function(m) {
        var body = document.body;
        var html = document.documentElement;
        var h = Math.max(body.scrollHeight, body.offsetHeight,
                         html.clientHeight, html.scrollHeight, html.offsetHeight);
        window.preHeight = h;
        pushMessage(m);
        window.__SCScrollViewToBottomIfRequired();
    };
    window.__SCScrollViewToBottomIfRequired = function() {
        if (window.pageYOffset + window.innerHeight == window.preHeight || window.preHeight < window.innerHeight) {
            window.__SCScrollViewToBottom();
        }
    };
    window.__SCScrollByPointNumber = function(p) {
        window.scrollTo(0, window.pageYOffset + p);
    };
    window.__SCScrollViewToBottom = function() {
        var body = document.body;
        var html = document.documentElement;
        var h = Math.max(body.scrollHeight, body.offsetHeight,
                         html.clientHeight, html.scrollHeight, html.offsetHeight);
        window.scrollTo(0, Math.max(0, h - window.innerHeight));
        window.preHeight = h;
    };
})();