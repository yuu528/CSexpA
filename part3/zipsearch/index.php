<!DOCTYPE html>
<html>
	<head>
		<title>ZipSearch</title>

		<meta charset="utf-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0"/>

		<!-- Materialize -->
		<link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/css/materialize.min.css">
		<script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/js/materialize.min.js"></script>

		<script src="index.js"></script>
	</head>
	<body>
		<form action="result.php" method="get" target="frame-result" id="form">
			<p>郵便番号または住所の漢字・カナ表記のいずれかを入力し、検索ボタンを押してください。</p>
			<input name="query" id="input-query" type="text">
			<button type="submit" id="btn-submit">検索</button>
		</form>

		<iframe name="frame-result" frameborder="no" width="100%" id="frame"></iframe>
	</body>
</html>
