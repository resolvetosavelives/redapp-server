const ACCESS_LIST_INPUT_SELECTOR = "input.access-input"
const facilityAccessDiv = () => document.getElementById("facility-access")
const selectAllFacilitiesDiv = () => document.getElementById("select-all-facilities")
const facilityAccessItemsAccessRatio = () => document.getElementsByClassName("access-ratio")
const facilityAccessItemsPadding = () => document.getElementsByClassName("access-item__padding")
const facilityAccessPowerUser = () => document.getElementById("facility-access-power-user")
//
// loads at page refresh
//
window.addEventListener("DOMContentLoaded", inviteAdmin);
window.addEventListener("DOMContentLoaded", editAdmin);

function inviteAdmin() {
  accessLevelListener()
  selectAccessLevels()
  selectAllListener()
  checkboxItemListener()
  resourceRowCollapseListener()
}

function editAdmin() {
  // list of all checkboxes under facilityAccessDiv()
  const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, facilityAccessDiv())
  const checkedCheckboxes = checkboxes.filter(check => check.checked)

  for (const checkbox of checkedCheckboxes) {
    updateParentCheckedState(checkbox, ACCESS_LIST_INPUT_SELECTOR)
  }

  selectAllFacilitiesDiv().checked = checkboxes.every(checkbox => checkbox.checked)
}

//
// listeners
//
function selectAllListener() {
  if (!selectAllFacilitiesDiv()) return

  const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, facilityAccessDiv())

  selectAllFacilitiesDiv().addEventListener("change", () => {
    for (const checkbox of checkboxes) {
      checkbox.checked = selectAllFacilitiesDiv().checked
    }
  })
}

function accessLevelListener() {
  $("#access_level").change(onAccessLevelChanged)
}

function checkboxItemListener() {
  // list of all checkboxes under facilityAccessDiv()
  const checkboxes = nodeListToArray(ACCESS_LIST_INPUT_SELECTOR, facilityAccessDiv())

  addEventListener("change", e => {
    const targetCheckbox = e.target

    // exit if change event did not come from list of checkboxes
    if (checkboxes.indexOf(targetCheckbox) === -1) return
    updateChildrenCheckedState(targetCheckbox, ACCESS_LIST_INPUT_SELECTOR)
    updateParentCheckedState(targetCheckbox, ACCESS_LIST_INPUT_SELECTOR)
  })
}

function resourceRowCollapseListener() {
  const collapsibleItems = [
    facilityAccessItemsPadding(),
    facilityAccessItemsAccessRatio()
  ].map(htmlCollection => Array.from(htmlCollection)).flat()
  
  for (const item of collapsibleItems) {
    item.addEventListener("click", onFacilityAccessItemToggled)
  }
}

//
// behaviour
//

function toggleAccessTreeVisiblity(isPoweruser) {
  if (isPoweruser) {
    facilityAccessDiv().classList.add("hidden")
    facilityAccessPowerUser().classList.remove("hidden")
  } else {
    facilityAccessDiv().classList.remove("hidden")
    facilityAccessPowerUser().classList.add("hidden")
  }
}

function onAccessLevelChanged({ target }) {
  toggleAccessTreeVisiblity(target.value === "power_user")
}

function toggleItemCollapsed(element) {
  const collapsed = element.classList.contains("collapsed")

  if (collapsed) {
    element.classList.remove("collapsed")
  } else {
    element.classList.add("collapsed")
  }
}

function onFacilityAccessItemToggled({target}) {
  const children = Array.from(target.closest("li").childNodes)
  const parentItem = target.closest(".access-item")
  const wrapper = children.find(containsClass("access-item-wrapper"))

  if (wrapper) {
    toggleItemCollapsed(parentItem)
  }
}

function updateParentCheckedState(element, selector) {
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
  if (element !== parent) updateParentCheckedState(parent, selector)
}

function updateChildrenCheckedState(parent, selector) {
  // check/uncheck children (includes check itself)
  const children = nodeListToArray(selector, parent.closest("li"))

  children.forEach(child => {
    // reset indeterminate state for children
    child.indeterminate = false
    child.checked = parent.checked
  })
}

//
// helpers
//

// helper function to create nodeArrays (not collections)
const nodeListToArray = (selector, parent = document) =>
  [].slice.call(parent.querySelectorAll(selector))

// returns a function that checks if element contains class
const containsClass = (className) => ({classList}) =>
  classList && classList.contains(className)

// initialize the access_level select dropdown
function selectAccessLevels() {
  $("#access_level").selectpicker({
    noneSelectedText: "Select an access level..."
  });
}
