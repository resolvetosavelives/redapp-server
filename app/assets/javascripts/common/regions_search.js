RegionsSearch = function () {
  this.resultToRow = (searchQuery, result) => {
    const name = result["name"]
    const regex = new RegExp(searchQuery, "ig")
    const highlightedName = name.replace(regex, "<strong>$&</strong>")

    let html = $("template#result-row").html();
    let $html = $(html)

    $html.find(".ancestors").append(result["ancestors"])
    let link = $html.find("a")
    link.append(highlightedName)
    link.attr("href", result["link"])

    return $html
  }

  this.noResultsFound = (searchQuery) => {
    let html = $("template#no-results-found").html();
    let $html = $(html);
    $html.find(".search-query").html(searchQuery);

    return $html;
  }

  this.showSpinner = () => {
    let spinner = $(".typeahead-spinner").first().clone();
    spinner.css({display: "block"});
    this.populateDropdown(spinner);
  }

  this.populateDropdown = (body) => {
    $(".typeahead .typeahead-dropdown").html(body)
  }

  this.populateSearchResults = (searchQuery, response) => {
    if (response.length) {
      let html = response.map((record) => {
        return this.resultToRow(searchQuery, record)
      })
      this.populateDropdown(html);
    } else {
      this.populateDropdown(this.noResultsFound(searchQuery))
    }
  }

  this.clearDropDown = () => {
    $(".typeahead-dropdown").empty();
  }

  this.searchRequest = (e) => {
    let searchQuery = e.value;
    if (searchQuery === "") {
      this.clearDropDown()
      return false
    }
    if (searchQuery && searchQuery.length) {
      this.showSpinner();
      $.ajax({
        url: e.form.action,
        data: {
          "query": searchQuery,
        },
        success: (res) => {
          this.populateSearchResults(searchQuery, res)
        }
      })
    } else {
      console.log("invalid or empty search query")
      return false
    }
  }

  this.debounce = (func, wait = 400) => {
    let timeout;
    return function (...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };

      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  }

  this.search = this.debounce(this.searchRequest);
}