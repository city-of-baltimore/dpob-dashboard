(function () {
  "use strict";

  var glossary = document.getElementById("glossary");
  var glossarySearch = document.getElementById("glossary-search");
  var glossaryTerms = document.querySelectorAll(".glossary-term");
  var glossaryData = typeof glossary_data === "undefined" ? [] : glossary_data;

  function forEachNode(nodes, callback) {
    for (var i = 0; i < nodes.length; i += 1) {
      callback(nodes[i]);
    }
  }

  function setTermsHidden(hidden) {
    forEachNode(glossaryTerms, function (term) {
      term.setAttribute("hidden-term", hidden ? "true" : "false");
    });
  }

  function searchGlossary(search, by) {
    for (var i = 0; i < glossaryData.length; i += 1) {
      var value = glossaryData[i];
      var term = document.getElementById(value.slug);

      if (term) {
        term.setAttribute(
          "hidden-term",
          value[by].toLowerCase().indexOf(search) < 0 ? "true" : "false"
        );
      }
    }
  }

  function findFirst(data, by, match) {
    for (var i = 0; i < data.length; i += 1) {
      if (data[i][by] === match) {
        return data[i];
      }
    }
    return null;
  }

  function isGlossaryHidden() {
    if (window.getComputedStyle) {
      return window.getComputedStyle(glossary).display === "none";
    }
    return glossary.currentStyle.display === "none";
  }

  if (!glossary || !glossarySearch) {
    return;
  }

  forEachNode(document.querySelectorAll("a[define]"), function (link) {
    link.addEventListener("click", function () {
      var slug = link.getAttribute("define");
      var searchObject = findFirst(glossaryData, "slug", slug);

      if (!slug || !searchObject) {
        return;
      }

      setTermsHidden(true);
      document.getElementById(slug).setAttribute("hidden-term", "false");
      glossarySearch.value = searchObject.term.toLowerCase();
      glossary.style.display = "block";
    });
  });

  forEachNode(document.querySelectorAll(".glossary-toggle"), function (toggle) {
    toggle.addEventListener("click", function () {
      glossary.style.display = isGlossaryHidden() ? "block" : "none";
      setTermsHidden(false);
    });
  });

  forEachNode(document.querySelectorAll(".glossary-clear"), function (clear) {
    clear.addEventListener("click", function () {
      glossarySearch.value = "";
    });
  });

  glossarySearch.addEventListener("input", function () {
    searchGlossary(glossarySearch.value.toLowerCase(), "term");
  });
}());
