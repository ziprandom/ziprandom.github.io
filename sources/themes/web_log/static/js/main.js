window.jQuery(document).ready(function() {
  /*******************************************************************
   * 1. replace css class "src" and "example" with "prettyprint", for
   *    prettify.js to render
   * 2. replace detail language css class, e.g. "src-scheme" to
   *    "lang-scheme" per the description of prettify.js
   ******************************************************************/
  var $blocks = $('pre code');
  $blocks.each(function(index) {
    var self = $(this);
    var classes = self.attr('class').split(/\s+/);
    $.each(classes, function(idx, cls) {
      if (cls.substring(0, 9) === 'language-') {
        var lang = cls.substring(9);
        self.removeClass(cls).addClass(lang);
      }
    });
  });
  hljs.initHighlightingOnLoad()
});
