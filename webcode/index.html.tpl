<html>
<head>
    <title>Evidence</title>
    <link href="/styles.css" rel="stylesheet">
    <script src="/script.js"></script>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.0/jquery.min.js"></script>
</head>
<body>
  <div style="width:100%;"></div>
    <h1>Evidence</h1>
    <script type="text/javascript">
      getEvidence();
   </script>
    <div id="result">
    </div>
    <br/><br/>
    <b>Upload new file:</b>
    <table style="border: 1px solid transparent;">
      <tr><td style="border: 1px solid transparent;">
        <input type="file" id="myFile" name="filename">
      </td></tr>
      <tr><td style="border: 1px solid transparent;">
        <button id="submitButton" onclick="uploadEvidence()">Submit</button>
      </td></tr>
    </table>
  </div>
  <footer>
    <img src="/Cloud_Ace_Final.png" width="250px" style="display:block;margin-left:auto;margin-right:auto;" />
  </footer>
</body>
</html>