const statusComplete = "Complete";
const statusReceived = "Received";

function initBoxListeners () {
  const originalPallet = $("#pallet-assignment").val();
  const originalContainer = $("#container-assignment").val();

  $(document).on("change", "#pallet-assignment", () => {
    var pallet = $("#pallet-assignment").val();
    var container = $("#container-assignment").val();
    if (container === "" && pallet === "") $("#assignmentModal").modal();
  });

  $(document).on("change", "#container-assignment", () => {
    var pallet = $("#pallet-assignment").val();
    var container = $("#container-assignment").val();

    if (container === "" && pallet === "") {
      $("#assignmentModal").modal();
    } else if (originalPallet !== "") {
      var palletName = $("#pallet-assignment option:selected").text();
      var containerName = $("#container-assignment option:selected").text();
      $("#assignmentModalBody").html(`You are changing the assignment of this box from a pallet (${palletName}) to a container (${containerName}).`)
      $("#assignmentModal").modal();
    }
  });

  $(document).on("change", "#pallet-assignment", () => {
    var pallet = $("#pallet-assignment").val();
    var container = $("#container-assignment").val();

    if (container === "" && pallet === "") {
      $("#assignmentModal").modal();
    } else if (originalContainer !== "") {
      var palletName = $("#pallet-assignment option:selected").text();
      var containerName = $("#container-assignment option:selected").text();
      $("#assignmentModalBody").html(`You are changing the assignment of this box from a container (${containerName}) to a pallet (${palletName}).`)
      $("#assignmentModal").modal();
    }
  });
}

// TODO: Below can be rafactored; they are identical
function initPalletListeners() {
  $(document).on("change", "#status", () => {
    var status = $("#status option:selected").text();
    if (status == statusComplete || status == statusReceived) $("#statusModal").modal();
  });

  $(document).on("change", "#container-assignment", () => {
    var container = $("#container-assignment").val();
    if (container === "") $("#assignmentModal").modal();
  });
}

function initContainerListeners() {
  $(document).on("change", "#status", () => {
    var status = $("#status option:selected").text();
    if (status == statusComplete || status == statusReceived) $("#statusModal").modal();
  });

  $(document).on("change", "#shipment-assignment", () => {
    var shipment = $("#shipment-assignment").val();
    if (shipment === "") $("#assignmentModal").modal();
  });
}

function initShipmentListeners() {
  $(document).on("change", "#status", () => {
    var status = $("#status option:selected").text();
    if (status == statusComplete || status == statusReceived) $("#statusModal").modal();
  });
}

$(() => {
  if ($(".edit_box")[0] !== undefined) initBoxListeners();
  if ($(".edit_pallet")[0] !== undefined) initPalletListeners();
  if ($(".edit_container")[0] !== undefined) initContainerListeners();
  if ($(".edit_shipment")[0] !== undefined) initShipmentListeners();
});
