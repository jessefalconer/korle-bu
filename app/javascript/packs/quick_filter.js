function filterList() {
  var input, filter, manageTab, nameRow, p, i, txtValue;
  input = document.getElementById("quick-filter");
  filter = input.value.toUpperCase();
  manageTab = document.getElementById("manage");
  nameRow = manageTab.getElementsByClassName("inline-add-item");

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
  var input, filter, table, nameRow, td, i, txtValue;
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
  if (document.querySelector(".edit_packed_item") != null) {
    if (document.querySelector("#quick-filter") === null) return;

    $(document).on("click input", "#quick-filter", () => {
      filterList();
    });
  } else {
    const tables = ["pallets", "boxes", "container-items", "pallet-boxes", "container-boxes", "pallet-items", "box-items"]
    Reflect.apply(Array, undefined, tables).forEach(assoc => {
      const table  = document.getElementById(`filter-${assoc}-table`);

      if (table === null) return;

      $(document).on("click input", `#${assoc}-quick-filter`, () => {
        filterTable(table, assoc);
      });
    });
  }
});
