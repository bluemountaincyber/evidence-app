function getEvidence() {
  $.ajax({
    url: "${function_url}",
    type: "GET",
    success: (response, textStatus, jqXHR) => {
      populateTable(JSON.parse(response.replaceAll("'", '"')));
    },
    error: (jqXHR, textStatus, errorThrown) => {
      $("#result").html("ERROR!");
    }
  });
}

function populateTable(response) {
  table = "<table><tr><th>File name</th><th>MD5Sum</th><th>SHA1Sum</th></tr>"
  console.log(response.Items);
  response.Items.forEach(element => {
    table += "<tr><td>" + element.FileName.S + "</td><td>" + element.MD5Sum.S + "</td><td>" + element.SHA1Sum.S + "</td></tr>";
  });
  table += "</table>";
  $("#result").html(table);
}

function uploadEvidence() {
  var file = document.getElementById("myFile").files[0];
  if (file) {
    var reader = new FileReader();
    reader.readAsBinaryString(file);
    reader.onload = function (evt) {
      $.ajax({
        url: "${function_url}",
        type: "POST",
        data: JSON.stringify({
          file_data: btoa(reader.result),
          file_name: document.getElementById("myFile").files[0].name
        }),
        dataType: "text",
        success: (response, textStatus, jqXHR) => {
          alert("File uploaded successfully!");
          getEvidence();
        },
        error: (jqXHR, textStatus, errorThrown) => {
          alert("ERROR UPLOADING FILE");
          getEvidence();
        }
      });
    }
    reader.onerror = function (evt) {
      alert("Error reading file!");
    }
  }
}
