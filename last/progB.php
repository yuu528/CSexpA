<!DOCTYPE html>
<html lang="ja">
	<head>
		<title>実装Ｂの結果</title>
	</head>
	<body>
<?php
const DB_HOST = 'localhost';
const DB_USER = 'pi';
const DB_PASSWORD = 'csexpatestpassword';
const DB_NAME = 'CSexp1DB';

if(isset($_REQUEST["tag"])){
	echo "[Program B] Input tag = [".$_REQUEST["tag"]."]<br>";

	$mysqli = new mysqli(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);
	if(is_null($mysqli)) {
		echo 'DB Error';
	}

	$sqlq = $mysqli->prepare('SELECT * FROM tag IGNORE INDEX (i_tag) INNER JOIN geotag IGNORE INDEX (i_id) USING (id) WHERE tag.tag like ? ORDER BY time DESC LIMIT 100');
	$sqlq->bind_param('s', $_REQUEST['tag']);
	$sqlq->execute();
	$result = $sqlq->get_result();

	while($row = $result->fetch_assoc()) {
		echo "${row['id']},\"${row['time']}\",${row['latitude']},${row['longitude']},${row['url']}<br>";
	}
}else{
	echo "[Program B] Please input a tag.";
}
?>
	</body>
</html>
