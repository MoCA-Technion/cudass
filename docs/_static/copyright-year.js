/* Update copyright year in the footer at view time (no rebuild needed). */
(function () {
  var el = document.querySelector("div.copyright");
  if (el) {
    var y = new Date().getFullYear();
    el.textContent = el.textContent.replace(/\b20\d{2}\b/, String(y));
  }
})();
