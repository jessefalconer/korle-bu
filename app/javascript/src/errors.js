$(document).ready(function () {
  setTimeout((function () {
    var els = document.getElementsByClassName("flash");
    while (els[0]) {
      els[0].parentNode.removeChild(els[0]);
    }
  }), 10000);
});
