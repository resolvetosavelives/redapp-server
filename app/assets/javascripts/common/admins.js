//
// elements
//
const ACCESS_LIST_INPUT_SELECTOR = "input.access-input"
const ACCESS_LEVEL_POWER_USER = "power_user"

AdminAccess = function (accessDivId) {
  this.facilityAccess = document.getElementById(accessDivId)
}

AdminAccess.prototype = {
  accessLevel: () => document.getElementById("access_level"),
  facilityAccessPowerUser: () => document.getElementById("facility-access-power-user"),

  facilityAccessItemsPadding: function () {
    return document.getElementsByClassName("access-item__padding")
  },

  facilityAccessItemsAccessRatio: function () {
    return document.getElementsByClassName("access-ratio")
  },

  selectAllFacilitiesContainer: function () {
    return document.getElementById("select-all-facilities")
  },

  checkboxItemListener: function () {
    // list of all checkboxes under facilityAccess()
    const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, this.facilityAccess)
    addEventListener("change", e => {
      const targetCheckbox = e.target

      // exit if change event did not come from list of checkboxes
      if (checkboxes.indexOf(targetCheckbox) === -1) return

      this.updateChildrenCheckedState(targetCheckbox, ACCESS_LIST_INPUT_SELECTOR)
      this.updateParentCheckedState(targetCheckbox, ACCESS_LIST_INPUT_SELECTOR)
    })
  },

  resourceRowCollapseListener: function () {
    const collapsibleItems = [
      this.facilityAccessItemsPadding(),
      this.facilityAccessItemsAccessRatio()
    ].map(htmlCollection => Array.from(htmlCollection)).flat()

    for (const item of collapsibleItems) {
      item.addEventListener("click", this.onFacilityAccessItemToggled.bind(this))
    }
  },

  toggleAccessTreeVisibility: function (isPowerUser) {
    if (isPowerUser) {
      this.facilityAccess.classList.add("hidden")
      this.facilityAccessPowerUser().classList.remove("hidden")
    } else {
      this.facilityAccess.classList.remove("hidden")
      this.facilityAccessPowerUser().classList.add("hidden")
    }
  },

  onAccessLevelChanged: function ({ target }) {
    this.toggleAccessTreeVisibility(target.value === ACCESS_LEVEL_POWER_USER)
  },

  toggleItemCollapsed: function (element) {
    const collapsed = element.classList.contains("collapsed")

    if (collapsed) {
      element.classList.remove("collapsed")
    } else {
      element.classList.add("collapsed")
    }
  },

  onFacilityAccessItemToggled: function ({ target }) {
    const children = Array.from(target.closest("li").childNodes)
    const parentItem = target.closest(".access-item")
    const wrapper = children.find(containsClass("access-item-wrapper"))
    if (wrapper) {
      this.toggleItemCollapsed(parentItem)
    }
  },

  updateParentCheckedState: function (element, selector) {
    // find parent and sibling checkboxes
    const parent = (element.closest(["ul"]).parentNode).querySelector(selector)
    const siblings = nodeListToArray(selector, parent.closest("li").querySelector(["ul"]))

    // get checked state of siblings
    // are every or some siblings checked (using Boolean as test function)
    const checkStatus = siblings.map(check => check.checked)
    const every = checkStatus.every(Boolean)
    const some = checkStatus.some(Boolean)

    // check parent if all siblings are checked
    // set indeterminate if not all and not none are checked
    parent.checked = every
    parent.indeterminate = some && !every

    // recurse until check is the top most parent
    if (element !== parent) {
      this.updateParentCheckedState(parent, selector)
    } else {
      this.updateSelectAllCheckbox()
    }
  },

  updateChildrenCheckedState: function (parent, selector) {
    // check/uncheck children (includes check itself)
    const children = nodeListToArray(selector, parent.closest("li"))

    children.forEach(child => {
      // reset indeterminate state for children
      child.indeterminate = false
      child.checked = parent.checked
    })
  },

  onAsyncLoaded: function () {
    const _self = this
    document.addEventListener('render_async_load', function (_event) {
      _self.resourceRowCollapseListener()
    });
  },

  initialize: function () {
    this.onAsyncLoaded()
  }
}

AdminAccessInvite = function (accessDivId) {
  this.facilityAccess = document.getElementById(accessDivId)
}

AdminAccessInvite.prototype = Object.create(AdminAccess.prototype)

AdminAccessInvite.prototype = Object.assign(AdminAccessInvite.prototype, {
  selectAllFacilitiesInput: () => document.getElementById("select-all-facilities-input"),

  updateSelectAllCheckbox: function () {
    const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, this.facilityAccess)
    this.selectAllFacilitiesInput().checked = checkboxes.every(checkbox => checkbox.checked)
  },

  updateIndeterminateCheckboxes: function () {
    // list of all checkboxes under facilityAccess
    const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, this.facilityAccess)

    // go through all the checkboxes that are pre-checked and update their parents accordingly
    for (const checkbox of checkboxes) {
      if (!checkbox.checked) continue

      // a large tree can take a lot of time to load on the DOM,
      // so we queue up our updates by requesting frames so as to not cause overwhelming repaints
      const _self = this
      requestAnimationFrame(function () {
        _self.updateParentCheckedState(checkbox, ACCESS_LIST_INPUT_SELECTOR)
      })
    }

    this.updateSelectAllCheckbox()
  },

  selectAllButtonListener: function () {
    this.selectAllFacilitiesContainer().hidden = false

    const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, this.facilityAccess)
    const _self = this
    this.selectAllFacilitiesInput().addEventListener("change", () => {
      for (const checkbox of checkboxes) {
        checkbox.indeterminate = false
        checkbox.checked = _self.selectAllFacilitiesInput().checked
      }
    })
  },

  accessLevelSelector: function () {
    const accessLevel = $("#access_level")
    // initialize the access_level select dropdown
    accessLevel.selectpicker({
      noneSelectedText: "Select an access level..."
    });
  },

  accessLevelListener: function () {
    this.accessLevel().addEventListener("change", this.onAccessLevelChanged.bind(this))
  },

  onDOMLoaded: function () {
    const _self = this
    window.addEventListener("DOMContentLoaded", function () {
      _self.accessLevelSelector()
      _self.accessLevelListener()
    })
  },

  onAsyncLoaded: function () {
    const _self = this
    document.addEventListener('render_async_load', function () {
      _self.selectAllButtonListener()
      _self.checkboxItemListener()
      _self.resourceRowCollapseListener()
      _self.updateIndeterminateCheckboxes()
    });
  },

  initialize: function () {
    this.onDOMLoaded()
    this.onAsyncLoaded()
  }
})


AdminAccessEdit = function (accessDivId) {
  this.facilityAccess = document.getElementById(accessDivId)
}

AdminAccessEdit.prototype = Object.create(AdminAccessInvite.prototype)

AdminAccessEdit.prototype = Object.assign(AdminAccessEdit.prototype, {
  accessLevelSelector: function () {
    // super
    AdminAccessInvite.prototype.accessLevelSelector.call(this)
    const accessLevel = $("#access-level")
    this.toggleAccessTreeVisibility(accessLevel.val() === ACCESS_LEVEL_POWER_USER)
  }
})

//
// helpers
//
const nodeListToArray = (selector, parent = document) =>
  // create nodeArrays (not collections)
  [].slice.call(parent.querySelectorAll(selector))

// return a function that checks if element contains class
const containsClass = (className) => ({ classList }) =>
  classList && classList.contains(className)