function filterList(tabList, assoc) {
  var input, filter, nameRow, p, i, txtValue;
  input = document.getElementById(`${assoc}-quick-filter`);
  filter = input.value.toUpperCase();
  nameRow = tabList.getElementsByClassName("inline-add-item");

  for (i = 0; i < nameRow.length; i++) {
    p = nameRow[i].getElementsByTagName("p")[0];
    txtValue = p.textContent || p.innerText;
    if (txtValue.toUpperCase().indexOf(filter) > -1) {
      nameRow[i].style.display = "";
    } else {
      nameRow[i].style.display = "none";
    }
  }
}

function filterTable(table, assoc) {
  var input, filter, nameRow, td, i, txtValue;
  input = document.getElementById(`${assoc}-quick-filter`);
  filter = input.value.toUpperCase();
  nameRow = table.getElementsByClassName("filter-row");

  for (i = 0; i < nameRow.length; i++) {
    td = nameRow[i].getElementsByTagName("td")[0];
    txtValue = td.textContent || td.innerText;
    if (txtValue.toUpperCase().indexOf(filter) > -1) {
      nameRow[i].style.display = "";
    } else {
      nameRow[i].style.display = "none";
    }
  }
}

$(() => {
  const types = [
    "pallets", "boxes", "pallet-boxes", "container-boxes", "packed-items", "manage-items",
    "unpack-items", "history-items", "boxed-items", "palletized-items", "containerized-items"
  ]

  Reflect.apply(Array, undefined, types).forEach(assoc => {
    var table  = document.getElementById(`filter-${assoc}-table`);
    var tabList = document.getElementById(assoc);

    if (table !== null) {
      $(document).on("click input", `#${assoc}-quick-filter`, () => {
        filterTable(table, assoc);
      });
    } else if (tabList !== null ){
      $(document).on("click input", `#${assoc}-quick-filter`, () => {
        filterList(tabList, assoc);
      });
    }
  });
});
