hushly.api = "https://app.hushly.com/";
hushly.cdn = "https://app.hushly.com/";
hushly.css = "https://app.hushly.com/assets/widget-f5d8464715180da8c4744622880f4772.css";

var widgetSource = "https://app.hushly.com/assets/widget-88a298fbacae9e84677c6fc759c32e4c.js";
"undefined" != typeof window._hlyc && (widgetSource = window._hlyc),

function() {
    var scriptTag = document.createElement("script"); 
    scriptTag.type = "text/javascript"; 
    scriptTag.async = true; 
    scriptTag.src = widgetSource; 
    (document.getElementsByTagName("head")[0] 
                    || document.documentElement).appendChild(scriptTag);
}();