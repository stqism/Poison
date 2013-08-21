(function() {
    window.preHeight = 0;
    window.__SCPostMessagePost = function() {
        var body = document.body;
        var html = document.documentElement;
        var h = Math.max(body.scrollHeight, body.offsetHeight,
                         html.clientHeight, html.scrollHeight, html.offsetHeight);
        console.log(window.preHeight);
        console.log(window.pageYOffset + window.innerHeight);
        if (window.pageYOffset + window.innerHeight == window.preHeight || window.preHeight < window.innerHeight) {
            window.scrollTo(0, Math.max(0, h - window.innerHeight));
        }
        window.preHeight = h;
    }
})();