function filter() {
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

$(() => {
  if (document.querySelector(".edit_packed_item") === null) { return; }

  $(document).on("click input", "#quick-filter", () => {
    filter();
  });
});
