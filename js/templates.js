window.require.register("index", function(exports, require, module) {
  module.exports = function anonymous(locals) {
  var buf = [];
  buf.push("<!DOCTYPE html><head><link rel=\"stylesheet\" href=\"css/app.css\"><link href=\"http://fonts.googleapis.com/css?family=Roboto\" rel=\"stylesheet\"></head><body><div id=\"game\" style=\"position:absolute;width:100%;height:100%\"><div id=\"score\" style=\"font-size:25px;color: white;display:none;z-index=10\">0</div><div id=\"blocker\"><div id=\"title\" style=\"font-size:60px;color: white;margin-top:100px;padding-left:10%;font-family: Roboto, sans-serif;\">Dolphins Beneath The Surface</div><div id=\"instructions\" style=\"font-size:30px;color:white;margin-top:20%;padding-left:40%;white-space:pre;font-family: Roboto, sans-serif;\">Alternate between A/D to Swim.\nClick to Start\nGrab as many Rings as you can!</div></div></div><script src=\"js/vendor.js\"></script><script src=\"js/app.js\" defer onload=\"require('scripts/game');\"></script></body>");;return buf.join("");
  };
});
