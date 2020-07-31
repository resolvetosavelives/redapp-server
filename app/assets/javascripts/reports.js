window.addEventListener("DOMContentLoaded", initializeCharts);

let lightGreenColor = "rgba(242, 248, 245, 1)";
let darkGreenColor = "rgba(0, 122, 49, 1)";
let mediumGreenColor = "rgba(92, 255, 157, 1)";
let lightRedColor = "rgba(255, 235, 238, 1)";
let darkRedColor = "rgba(255, 51, 85, 1)";
let lightPurpleColor = "rgba(238, 229, 252, 1)";
let darkGreyColor = "rgba(108, 115, 122, 1)";
let mediumGreyColor = "rgba(173, 178, 184, 1)";
let lightGreyColor = "rgba(240, 242, 245, 1)";

function initializeCharts() {
  const data = getReportingData();

  const controlledGraphConfig = createGraphConfig([{
    data: data.controlRate,
    rgbaLineColor: darkGreenColor,
    rgbaBackgroundColor: lightGreenColor,
    label: "control rate",
  }], "line");
  controlledGraphConfig.options = createGraphOptions(
    false,
    25,
    100,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.controlledPatients],
  );
  const controlledGraphCanvas = document.getElementById("controlledPatientsTrend");
  if (controlledGraphCanvas) {
    new Chart(controlledGraphCanvas.getContext("2d"), controlledGraphConfig);
  }

  const noBPMeasureGraphConfig = createGraphConfig([
    {
      data: data.controlRate,
      rgbaBackgroundColor: mediumGreyColor,
      hoverBackgroundColor: mediumGreyColor,
      label: "lost to follow-up",
    },
  ], "bar");
  noBPMeasureGraphConfig.options = createGraphOptions(
    false,
    25,
    100,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.uncontrolledPatients],
  );
  const noBPMeasureGraphCanvas = document.getElementById("noBPMeasureTrend");
  if (noBPMeasureGraphCanvas) {
    new Chart(noBPMeasureGraphCanvas.getContext("2d"), noBPMeasureGraphConfig);
  }

  const uncontrolledGraphConfig = createGraphConfig([
    {
      data: data.uncontrolledRate,
      rgbaBackgroundColor: lightRedColor,
      rgbaLineColor: darkRedColor,
      label: "not under control rate",
    }
  ], "line");
  uncontrolledGraphConfig.options = createGraphOptions(
    false,
    25,
    100,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.uncontrolledPatients],
  );
  const uncontrolledGraphCanvas = document.getElementById("uncontrolledPatientsTrend");
  if (uncontrolledGraphCanvas) {
    new Chart(uncontrolledGraphCanvas.getContext("2d"), uncontrolledGraphConfig);
  }

  const maxRegistrations = Math.max(...Object.values(data.registrations));
  const suggestedMax = Math.round(maxRegistrations) * 1.15;
  const stepSize = Math.round(suggestedMax / 3);
  const cumulativeRegistrationsGraphConfig = createGraphConfig([
    {
      data: data.registrations,
      rgbaBackgroundColor: lightPurpleColor,
      hoverBackgroundColor: lightPurpleColor,
    },
  ], "bar");
  cumulativeRegistrationsGraphConfig.options = createGraphOptions(
    false,
    stepSize,
    suggestedMax,
    formatNumberWithCommas,
    formatSumTooltipText,
  );
  const cumulativeRegistrationsGraphCanvas = document.getElementById("cumulativeRegistrationsTrend");
  if (cumulativeRegistrationsGraphCanvas) {
    new Chart(cumulativeRegistrationsGraphCanvas.getContext("2d"), cumulativeRegistrationsGraphConfig);
  }

  const visitDetailsGraphConfig = createGraphConfig([
    {
      data: data.controlRate,
      rgbaBackgroundColor: mediumGreenColor,
      rgbaLineColor: mediumGreenColor,
      label: "control rate",
    },
    {
      data: data.uncontrolledRate,
      rgbaBackgroundColor: darkRedColor,
      rgbaLineColor: darkRedColor,
      label: "not under control rate",
    },
  ], "bar");
  visitDetailsGraphConfig.options = createGraphOptions(
    true,
    25,
    formatValueAsPercent,
    formatRateTooltipText,
    [data.controlledPatients, data.uncontrolledPatients],
  );
  const visitDetailsGraphCanvas = document.getElementById("missedVisitDetails");
  if (visitDetailsGraphCanvas) {
    new Chart(visitDetailsGraphCanvas.getContext("2d"), visitDetailsGraphConfig);
  }
};

function getReportingData() {
  const $reportingDiv = document.getElementById("reporting");
  const $newData = document.getElementById("data-json");
  const jsonData = JSON.parse($newData.textContent);

  const controlRate = jsonData.controlled_patients_rate;
  const controlledPatients = jsonData.controlled_patients;
  const registrations = jsonData.registrations;
  const uncontrolledRate = jsonData.uncontrolled_patients_rate;
  const uncontrolledPatients = jsonData.uncontrolled_patients;

  let data = {
    controlRate: controlRate,
    controlledPatients: controlledPatients,
    registrations: registrations,
    uncontrolledRate: uncontrolledRate,
    uncontrolledPatients: uncontrolledPatients,
  };

  return data;
};

function createGraphConfig(datasetsConfig, graphType) {
  return {
    type: graphType,
    data: {
      labels: Object.keys(datasetsConfig[0].data),
      datasets: datasetsConfig.map(dataset => {
        return {
          label: dataset.label,
          backgroundColor: dataset.rgbaBackgroundColor,
          borderColor: dataset.rgbaLineColor ? dataset.rgbaLineColor : undefined,
          borderWidth: dataset.rgbaLineColor ? 1 : undefined,
          pointBackgroundColor: dataset.rgbaLineColor,
          hoverBackgroundColor: dataset.hoverBackgroundColor,
          data: Object.values(dataset.data),
        };
      }),
    },
  };
};

function createGraphOptions(isStacked, stepSize, suggestedMax, tickCallbackFunction, tooltipCallbackFunction, dataSum) {
  return {
    animation: false,
    responsive: true,
    maintainAspectRatio: false,
    layout: {
      padding: {
        left: 0,
        right: 0,
        top: 0,
        bottom: 0
      }
    },
    elements: {
      point: {
        pointStyle: "circle",
        backgroundColor: "rgba(81, 205, 130, 1)",
        hoverRadius: 5,
      },
    },
    legend: {
      display: false,
    },
    scales: {
      xAxes: [{
        stacked: isStacked,
        display: true,
        gridLines: {
          display: true,
          drawBorder: false,
        },
        ticks: {
          fontColor: "#ADB2B8",
          fontSize: 14,
          fontFamily: "Roboto Condensed",
          maxRotation: 0,
          minRotation: 0
        }
      }],
      yAxes: [{
        stacked: isStacked,
        display: true,
        gridLines: {
          display: true,
          drawBorder: false,
        },
        ticks: {
          fontColor: "#ADB2B8",
          fontSize: 12,
          fontFamily: "Roboto Condensed",
          stepSize,
          suggestedMax,
          suggestedMin: 0,
          callback: tickCallbackFunction,
        }
      }],
    },
    tooltips: {
      backgroundColor: "rgb(0, 0, 0)",
      bodyAlign: "center",
      bodyFontFamily: "Roboto Condensed",
      bodyFontSize: 12,
      caretSize: 6,
      displayColors: false,
      position: "nearest",
      titleAlign: "center",
      titleFontFamily: "Roboto Condensed",
      titleFontSize: 16,
      xAlign: "center",
      xPadding: 12,
      yAlign: "bottom",
      yPadding: 12,
      callbacks: {
        title: function() {},
        label: function(tooltipItem, data) {
          return tooltipCallbackFunction(tooltipItem, data, dataSum);
        },
      },
    }
  };
};

function formatRateTooltipText(tooltipItem, data, sumData) {
  const datasetIndex = tooltipItem.datasetIndex;
  const total = formatNumberWithCommas(sumData[datasetIndex][tooltipItem.label]);
  const date = tooltipItem.label;
  const label = data.datasets[datasetIndex].label;
  const percent = Math.round(tooltipItem.value);
  return `${percent}% ${label} (${total} patients) in ${date}`;
}

function formatSumTooltipText(tooltipItem) {
  return `${formatNumberWithCommas(tooltipItem.value)} patients registered in ${tooltipItem.label}`;
}

function formatValueAsPercent(value) {
  return `${value}%`;
}

function formatNumberWithCommas(value) {
  return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}
