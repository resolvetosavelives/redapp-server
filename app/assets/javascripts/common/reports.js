const darkGreenColor = "rgba(0, 122, 49, 1)";
const mediumGreenColor = "rgba(0, 184, 73, 1)";
const lightGreenColor = "rgba(242, 248, 245, 0.9)";
const darkRedColor = "rgba(184, 22, 49, 1)"
const mediumRedColor = "rgba(255, 51, 85, 1)";
const lightRedColor = "rgba(255, 235, 238, 0.9)";
const darkPurpleColor = "rgba(83, 0, 224, 1)";
const lightPurpleColor = "rgba(238, 229, 252, 0.9)";
const darkBlueColor = "rgba(12, 57, 102, 1)";
const mediumBlueColor = "rgba(0, 117, 235, 1)";
const lightBlueColor = "rgba(233, 243, 255, 0.9)";
const darkGreyColor = "rgba(108, 115, 122, 1)";
const mediumGreyColor = "rgba(173, 178, 184, 1)";
const lightGreyColor = "rgba(240, 242, 245, 0.9)";
const whiteColor = "rgba(255, 255, 255, 1)";
const transparent = "rgba(0, 0, 0, 0)";

window.addEventListener("DOMContentLoaded", function() {
  if(getChartDataNode()) {
    initializeCharts();
    initializeTables();
  }
});

function getChartDataNode() {
  return document.getElementById("data-json")
}

function initializeTables() {
  const tableSortAscending = { descending: false };
  const tableSortDescending = { descending: true };

  const cumulativeRegistrationsTable = document.getElementById("cumulative-registrations-table");
  const htnNotUnderControlTable = document.getElementById("htn-not-under-control-table");
  const noBPMeasureTable = document.getElementById("no-bp-measure-table");
  const htnControlledTable = document.getElementById("htn-controlled-table");

  if (htnControlledTable) {
    new Tablesort(htnControlledTable, tableSortAscending);
  }

  if (noBPMeasureTable) {
    new Tablesort(noBPMeasureTable, tableSortDescending);
  }

  if (htnNotUnderControlTable) {
    new Tablesort(htnNotUnderControlTable, tableSortDescending);
  }

  if (cumulativeRegistrationsTable) {
    new Tablesort(cumulativeRegistrationsTable, tableSortAscending);
  }
};

function getReportingData() {
  const jsonData = JSON.parse(getChartDataNode().textContent);

  return {
    controlRate: jsonData.controlled_patients_rate,
    controlledPatients: jsonData.controlled_patients,
    missedVisits: jsonData.missed_visits,
    missedVisitsRate: jsonData.missed_visits_rate,
    monthlyRegistrations: jsonData.registrations,
    adjustedRegistrations: jsonData.adjusted_registrations,
    cumulativeRegistrations: jsonData.cumulative_registrations,
    uncontrolledRate: jsonData.uncontrolled_patients_rate,
    uncontrolledPatients: jsonData.uncontrolled_patients,
    visitButNoBPMeasure: jsonData.visited_without_bp_taken,
    visitButNoBPMeasureRate: jsonData.visited_without_bp_taken_rate,
    periodInfo: jsonData.period_info
  };
};

function initializeCharts() {
  const data = getReportingData();

  const controlledGraphConfig = {
    type: "line",
    data: {
      labels: Object.keys(data.controlRate),
      datasets: [{
        label: "BP controlled",
        backgroundColor: lightGreenColor,
        borderColor: mediumGreenColor,
        borderWidth: 2,
        pointBackgroundColor: whiteColor,
        hoverBackgroundColor: whiteColor,
        hoverBorderWidth: 2,
        data: Object.values(data.controlRate),
        type: "line",
      }],
    },
  };

  controlledGraphConfig.options = createGraphOptions(
    [createAxisConfig({
      stacked: false,
      display: true,
      displayGridLines: false,
      drawBorder: true,
    })],
    [createAxisConfig({
      stacked: false,
      display: true,
      displayGridLines: true,
      drawBorder: false,
      stepSize: 25,
      max: 100,
    })],
  );
  controlledGraphConfig.options.tooltips = {
    enabled: false,
    custom: function (tooltip) {
      const cardNode = document.getElementById("bp-controlled");
      const mostRecentPeriod = cardNode.getAttribute("data-period");
      const rateNode = cardNode.querySelector("[data-rate]");
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const periodStartNode = cardNode.querySelector("[data-period-start]");
      const periodEndNode = cardNode.querySelector("[data-period-end]");
      const registrationsNode = cardNode.querySelector("[data-registrations]");
      const registrationsPeriodEndNode = cardNode.querySelector("[data-registrations-period-end]")
      let label = null;
      let rate = null;
      if (tooltip.dataPoints) {
        rate = tooltip.dataPoints[0].value + "%";
        label = tooltip.dataPoints[0].label;
      }
      else {
        rate = rateNode.getAttribute("data-rate");
        label = mostRecentPeriod;
      }
      const period = data.periodInfo[label];
      const adjustedRegistrations = data.adjustedRegistrations[label];
      const totalPatients = data.controlledPatients[label];

      rateNode.innerHTML = rate;
      totalPatientsNode.innerHTML = formatNumberWithCommas(totalPatients);
      periodStartNode.innerHTML = period.bp_control_start_date;
      periodEndNode.innerHTML = period.bp_control_end_date;
      registrationsNode.innerHTML = formatNumberWithCommas(adjustedRegistrations);
      registrationsPeriodEndNode.innerHTML = period.bp_control_start_date;
    }
  };

  const controlledGraphCanvas = document.getElementById("controlledPatientsTrend");
  if (controlledGraphCanvas) {
    new Chart(controlledGraphCanvas.getContext("2d"), controlledGraphConfig);
  }

  const missedVisitsConfig = {
    type: "line",
    data: {
      labels: Object.keys(data.missedVisitsRate),
      datasets: [{
        label: "Missed visits",
        backgroundColor: lightBlueColor,
        borderColor: mediumBlueColor,
        borderWidth: 2,
        pointBackgroundColor: whiteColor,
        hoverBackgroundColor: whiteColor,
        hoverBorderWidth: 2,
        data: Object.values(data.missedVisitsRate),
        type: "line",
      }],
    },
  };

  missedVisitsConfig.options = createGraphOptions(
    [createAxisConfig({
      stacked: false,
      display: true,
      displayGridLines: false,
      drawBorder: true,
    })],
    [createAxisConfig({
      stacked: false,
      display: true,
      displayGridLines: true,
      drawBorder: false,
      stepSize: 25,
      max: 100,
    })],
  );
  missedVisitsConfig.options.tooltips = {
    enabled: false,
    custom: function (tooltip) {
      const cardNode = document.getElementById("missed-visits");
      const mostRecentPeriod = cardNode.getAttribute("data-period");
      const rateNode = cardNode.querySelector("[data-rate]");
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const periodStartNode = cardNode.querySelector("[data-period-start]");
      const periodEndNode = cardNode.querySelector("[data-period-end]");
      const registrationsNode = cardNode.querySelector("[data-registrations]");
      const registrationsPeriodEndNode = cardNode.querySelector("[data-registrations-period-end]")
      let label = null;
      let rate = null;
      if (tooltip.dataPoints) {
        rate = tooltip.dataPoints[0].value + "%";
        label = tooltip.dataPoints[0].label;
      }
      else {
        rate = rateNode.getAttribute("data-rate");
        label = mostRecentPeriod;
      }
      const period = data.periodInfo[label];
      const adjustedRegistrations = data.adjustedRegistrations[label];
      const totalPatients = data.missedVisits[label];

      rateNode.innerHTML = rate;
      totalPatientsNode.innerHTML = formatNumberWithCommas(totalPatients);
      periodStartNode.innerHTML = period.bp_control_start_date;
      periodEndNode.innerHTML = period.bp_control_end_date;
      registrationsNode.innerHTML = formatNumberWithCommas(adjustedRegistrations);
      registrationsPeriodEndNode.innerHTML = period.bp_control_start_date;
    }
  };

  const missedVisitsGraphCanvas = document.getElementById("missedVisitsTrend");
  if (missedVisitsGraphCanvas) {
    new Chart(missedVisitsGraphCanvas.getContext("2d"), missedVisitsConfig);
  }

  const uncontrolledGraphConfig = createGraphConfig({
    datasets: [{
      data: data.uncontrolledRate,
      borderWidth: 2,
      rgbaLineColor: mediumRedColor,
      rgbaPointColor: whiteColor,
      rgbaBackgroundColor: lightRedColor,
      pointBackgroundColor: whiteColor,
      hoverBackgroundColor: whiteColor,
      label: "HTN not under control",
    }],
    graphType: "line",
  });
  uncontrolledGraphConfig.options = createGraphOptions(
    [createAxisConfig({
      stacked: false,
      display: true,
      displayGridLines: false,
      drawBorder: true,
    })],
    [createAxisConfig({
      stacked: false,
      display: true,
      displayGridLines: true,
      drawBorder: false,
      stepSize: 25,
      max: 100,
    })],
  );
  uncontrolledGraphConfig.options.tooltips = {
    enabled: false,
    custom: function (tooltip) {
      const cardNode = document.getElementById("bp-uncontrolled");
      const mostRecentPeriod = cardNode.getAttribute("data-period");
      const rateNode = cardNode.querySelector("[data-rate]");
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const periodStartNode = cardNode.querySelector("[data-period-start]");
      const periodEndNode = cardNode.querySelector("[data-period-end]");
      const registrationsNode = cardNode.querySelector("[data-registrations]");
      const registrationsPeriodEndNode = cardNode.querySelector("[data-registrations-period-end]")
      let label = null;
      let rate = null;
      if (tooltip.dataPoints) {
        rate = tooltip.dataPoints[0].value + "%";
        label = tooltip.dataPoints[0].label;
      }
      else {
        rate = rateNode.getAttribute("data-rate");
        label = mostRecentPeriod;
      }
      const period = data.periodInfo[label];
      const adjustedRegistrations = data.adjustedRegistrations[label];
      const totalPatients = data.uncontrolledPatients[label];

      rateNode.innerHTML = rate;
      totalPatientsNode.innerHTML = formatNumberWithCommas(totalPatients);
      periodStartNode.innerHTML = period.bp_control_start_date;
      periodEndNode.innerHTML = period.bp_control_end_date;
      registrationsNode.innerHTML = formatNumberWithCommas(adjustedRegistrations);
      registrationsPeriodEndNode.innerHTML = period.bp_control_start_date;
    }
  };

  const uncontrolledGraphCanvas = document.getElementById("uncontrolledPatientsTrend");
  if (uncontrolledGraphCanvas) {
    new Chart(uncontrolledGraphCanvas.getContext("2d"), uncontrolledGraphConfig);
  }

  const cumulativeRegistrationsYAxis = createAxisMaxAndStepSize(data.cumulativeRegistrations);
  const monthlyRegistrationsYAxis = createAxisMaxAndStepSize(data.monthlyRegistrations);

  const cumulativeRegistrationsGraphConfig = createGraphConfig({
    datasets: [
      {
        id: "cumulativeRegistrations",
        data: data.cumulativeRegistrations,
        borderWidth: 2,
        rgbaLineColor: darkPurpleColor,
        rgbaPointColor: whiteColor,
        rgbaBackgroundColor: transparent,
        pointBackgroundColor: whiteColor,
        hoverBackgroundColor: whiteColor,
        label: "cumulative registrations",
        graphType: "line",
      },
      {
        id: "monthlyRegistrations",
        data: data.monthlyRegistrations,
        rgbaBackgroundColor: lightPurpleColor,
        hoverBackgroundColor: darkPurpleColor,
        label: "monthly registrations",
        graphType: "bar",
      },
    ],
    graphType: "bar",
  });
  cumulativeRegistrationsGraphConfig.options = createGraphOptions(
    [createAxisConfig({
      stacked: true,
      display: true,
      displayGridLines: false,
      drawBorder: false,
    })],
    [
      createAxisConfig({
        stacked: true,
        display: true,
        displayGridLines: false,
        drawBorder: false,
        stepSize: cumulativeRegistrationsYAxis.stepSize,
        max: cumulativeRegistrationsYAxis.max,
        id: "cumulativeRegistrations",
        position: "left",
      }),
      createAxisConfig({
        stacked: true,
        display: true,
        displayGridLines: true,
        drawBorder: false,
        stepSize: monthlyRegistrationsYAxis.stepSize,
        max: monthlyRegistrationsYAxis.max,
        id: "monthlyRegistrations",
        position: "right",
      }),
    ],
  );
  cumulativeRegistrationsGraphConfig.options.tooltips = {
    enabled: false,
    custom: function (tooltip) {
      const cardNode = document.getElementById("cumulative-registrations");
      const mostRecentPeriod = cardNode.getAttribute("data-period");
      const totalPatientsNode = cardNode.querySelector("[data-total-patients]");
      const registrationsPeriodEndNode = cardNode.querySelector("[data-registrations-period-end]");
      const monthlyRegistrationsNode = cardNode.querySelector("[data-monthly-registrations]");
      const registrationsMonthEndNode = cardNode.querySelector("[data-registrations-month-end]");
      let label = null;
      if(tooltip.dataPoints) {
        label = tooltip.dataPoints[0].label;
      }
      else {
        label = mostRecentPeriod;
      }
      const period = data.periodInfo[label];
      const cumulativeRegistrations = data.cumulativeRegistrations[label];
      const monthlyRegistrations = data.monthlyRegistrations[label];

      monthlyRegistrationsNode.innerHTML = formatNumberWithCommas(monthlyRegistrations);
      totalPatientsNode.innerHTML = formatNumberWithCommas(cumulativeRegistrations);
      registrationsPeriodEndNode.innerHTML = period.bp_control_end_date;
      registrationsMonthEndNode.innerHTML = label;
    }
  };

  const cumulativeRegistrationsGraphCanvas = document.getElementById("cumulativeRegistrationsTrend");
  if (cumulativeRegistrationsGraphCanvas) {
    new Chart(cumulativeRegistrationsGraphCanvas.getContext("2d"), cumulativeRegistrationsGraphConfig);
  }

  const visitDetailsGraphConfig = createGraphConfig({
    datasets: [
      {
        data: data.controlRate,
        rgbaBackgroundColor: mediumGreenColor,
        hoverBackgroundColor: darkGreenColor,
        label: "HTN controlled",
        graphType: "bar",
      },
      {
        data: data.uncontrolledRate,
        rgbaBackgroundColor: mediumRedColor,
        hoverBackgroundColor: darkRedColor,
        label: "HTN not under control",
        graphType: "bar",
      },
      {
        data: data.visitButNoBPMeasureRate,
        rgbaBackgroundColor: mediumGreyColor,
        hoverBackgroundColor: darkGreyColor,
        label: "Visited in the last 3 months",
        graphType: "bar",
      },
      {
        data: data.missedVisitsRate,
        rgbaBackgroundColor: mediumBlueColor,
        hoverBackgroundColor: darkBlueColor,
        label: "No visit >3 months",
        graphType: "bar",
      }
    ],
    graphType: "bar",
    numberOfMonths: 6,
  });
  visitDetailsGraphConfig.options = createGraphOptions(
    [createAxisConfig({
      stacked: true,
      display: true,
      displayGridLines: false,
      drawBorder: false,
    })],
    [createAxisConfig({
      stacked: true,
      display: false,
      displayGridLines: false,
      drawBorder: false,
    })],
  );
  visitDetailsGraphConfig.options.tooltips = {
    mode: "x",
    enabled: false,
    custom: function (tooltip) {
      return stackedBarChartTooltip({
        tooltip,
        elementId: "visit-details",
        missedVisitsPatients: Object.values(data.missedVisits).slice(18, 24),
        visitButNoBPMeasurePatients: Object.values(data.visitButNoBPMeasure).slice(18, 24),
        uncontrolledPatients: Object.values(data.uncontrolledPatients).slice(18, 24),
        controlledPatients: Object.values(data.controlledPatients).slice(18, 24),
        adjustedRegistrations: Object.values(data.adjustedRegistrations).slice(18, 24),
        periodInfo: Object.values(data.periodInfo).slice(18, 24),
      });
    }
  };

  const visitDetailsGraphCanvas = document.getElementById("missedVisitDetails");
  if (visitDetailsGraphCanvas) {
    new Chart(visitDetailsGraphCanvas.getContext("2d"), visitDetailsGraphConfig);
  }
}

function createGraphConfig(config) {
  let { datasets, graphType, numberOfMonths } = config;
  let labels = {};
  if(numberOfMonths){
    labels = Object.keys(datasets[0].data).slice(-numberOfMonths);
  }
  else {
    labels = Object.keys(datasets[0].data);
  }
  const filteredDatasets = datasets.map((dataset, idx) => {
    let data = null;
    if(numberOfMonths){
      data = Object.values(dataset.data).slice(-numberOfMonths);
    } else {
      data = Object.values(dataset.data);
    }
    return {
      yAxisID: dataset.id,
      label: dataset.label,
      backgroundColor: dataset.rgbaBackgroundColor,
      borderColor: dataset.rgbaLineColor ? dataset.rgbaLineColor : undefined,
      borderWidth: dataset.borderWidth ? dataset.borderWidth : undefined,
      pointBackgroundColor: dataset.rgbaPointColor,
      hoverBackgroundColor: dataset.hoverBackgroundColor,
      hoverBorderWidth: dataset.borderWidth ? dataset.borderWidth : undefined,
      data: data,
      type: dataset.graphType ? dataset.graphType : "line",
    }
  });
  return {
    type: graphType,
    data: {
      labels: labels,
      datasets: filteredDatasets
      }
    }
  }

function createGraphOptions(xAxes, yAxes) {
  return {
    animation: false,
    responsive: true,
    maintainAspectRatio: false,
    layout: {
      padding: {
        left: 0,
        right: 0,
        top: 20,
        bottom: 0
      }
    },
    elements: {
      point: {
        pointStyle: "circle",
        hoverRadius: 5,
      },
    },
    legend: {
      display: false,
    },
    scales: {
      xAxes,
      yAxes,
    },
  };
}

function createAxisConfig(config) {
  const { stacked, display, displayGridLines, drawBorder, stepSize, max, id, position } = config;
  let axisConfig = {
    id,
    position: position ? position : "left",
    stacked,
    display,
    gridLines: {
      display: displayGridLines,
      drawBorder,
    },
    ticks: {
      autoSkip: false,
      fontColor: darkGreyColor,
      fontSize: 12,
      fontFamily: "Roboto Condensed",
      padding: 8,
      min: 0,
      beginAtZero: true,
      stepSize,
      max
    },
  };

  return axisConfig;
};

function createAxisMaxAndStepSize(data) {
  const maxDataValue = Math.max(...Object.values(data));
  const maxAxisValue = Math.round(maxDataValue * 1.15);
  const axisStepSize = Math.round(maxAxisValue / 2);

  return {
    max: maxAxisValue,
    stepSize: axisStepSize,
  };
};

function customTooltip(tooltip, numerator, denominator, periodInfo) {
  const { dataPoints } = tooltip;
  const valueElement = document.getElementById("bp-controlled-value");
  const defaultValue = valueElement.textContent;
  const endDateElement = document.getElementById("bp-controlled-end-date");
  const defaultEndDate = endDateElement.textContent;

  if (dataPoints == undefined) {
    valueElement.innerHTML = defaultValue;
    endDateElement.innerHTML = defaultEndDate;
  } else {
    valueElement.innerHTML = dataPoints[0].value;
    endDateElement.innerHTML = dataPoints[0].label;
  }
};

function stackedBarChartTooltip(config) {
  const {
    tooltip,
    elementId,
    missedVisitsPatients,
    visitButNoBPMeasurePatients,
    uncontrolledPatients,
    controlledPatients,
    adjustedRegistrations,
    periodInfo,
  } = config;
  const { dataPoints } = tooltip;

  const cardNode = document.getElementById(elementId);
  const missedVisitsRateNode = cardNode.querySelector("[data-missed-visits-rate]");
  const visitButNoBPMeasureRateNode = cardNode.querySelector("[data-visit-but-no-bp-measure-rate]");
  const uncontrolledRateNode = cardNode.querySelector("[data-uncontrolled-rate]");
  const controlledRateNode = cardNode.querySelector("[data-controlled-rate]");
  const missedVisitsPatientsNode = cardNode.querySelector("[data-missed-visits-patients]");
  const visitButNoBPMeasurePatientsNode = cardNode.querySelector("[data-visit-but-no-bp-measure-patients]");
  const uncontrolledPatientsNode = cardNode.querySelector("[data-uncontrolled-patients]");
  const controlledPatientsNode = cardNode.querySelector("[data-controlled-patients]");
  const periodStartNodes = cardNode.querySelectorAll("[data-period-start]");
  const periodEndNodes = cardNode.querySelectorAll("[data-period-end]");
  const cumulativeRegistrationsNodes = cardNode.querySelectorAll("[data-cumulative-registrations]");

  if (dataPoints == undefined) {
    missedVisitsRateNode.innerHTML = missedVisitsRateNode.getAttribute("data-missed-visits-rate");
    visitButNoBPMeasureRateNode.innerHTML = visitButNoBPMeasureRateNode.getAttribute("data-visit-but-no-bp-measure-rate");
    uncontrolledRateNode.innerHTML = uncontrolledRateNode.getAttribute("data-uncontrolled-rate");
    controlledRateNode.innerHTML = controlledRateNode.getAttribute("data-controlled-rate");
    missedVisitsPatientsNode.innerHTML = missedVisitsPatientsNode.getAttribute("data-missed-visits-patients");
    visitButNoBPMeasurePatientsNode.innerHTML = visitButNoBPMeasurePatientsNode.getAttribute("data-visit-but-no-bp-measure-patients");
    uncontrolledPatientsNode.innerHTML = uncontrolledPatientsNode.getAttribute("data-uncontrolled-patients");
    controlledPatientsNode.innerHTML = controlledPatientsNode.getAttribute("data-controlled-patients");
    periodStartNodes.forEach(node => node.innerHTML = periodStartNodes[0].getAttribute("data-period-start"));
    periodEndNodes.forEach(node => node.innerHTML = periodEndNodes[0].getAttribute("data-period-end"));
    cumulativeRegistrationsNodes.forEach(node => node.innerHTML = cumulativeRegistrationsNodes[0].getAttribute("data-cumulative-registrations"));
  } else {
    missedVisitsRateNode.innerHTML = dataPoints[3].value + "%";
    visitButNoBPMeasureRateNode.innerHTML = dataPoints[2].value + "%";
    uncontrolledRateNode.innerHTML = dataPoints[1].value + "%";
    controlledRateNode.innerHTML = dataPoints[0].value + "%";
    missedVisitsPatientsNode.innerHTML = formatNumberWithCommas(missedVisitsPatients[dataPoints[0].index]);
    visitButNoBPMeasurePatientsNode.innerHTML = formatNumberWithCommas(visitButNoBPMeasurePatients[dataPoints[0].index]);
    uncontrolledPatientsNode.innerHTML = formatNumberWithCommas(uncontrolledPatients[dataPoints[0].index]);
    controlledPatientsNode.innerHTML = formatNumberWithCommas(controlledPatients[dataPoints[0].index]);
    periodStartNodes.forEach(node => node.innerHTML = periodInfo[dataPoints[0].index].bp_control_start_date);
    periodEndNodes.forEach(node => node.innerHTML = periodInfo[dataPoints[0].index].bp_control_end_date);
    cumulativeRegistrationsNodes.forEach(node => node.innerHTML = formatNumberWithCommas(adjustedRegistrations[dataPoints[0].index]));
  }
}

function formatNumberWithCommas(value) {
  if(value == undefined) {
    return 0;
  }
  else {
    return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  }

}