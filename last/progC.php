<!DOCTYPE html>
<html lang="ja">
	<head>
		<title>実装Ｃの結果</title>
	</head>
	<body>
<?php
const DB_HOST = 'localhost';
const DB_USER = 'pi';
const DB_PASSWORD = 'csexpatestpassword';
const DB_NAME = 'CSexp1DB';
const DB_TABLE_TAG = 'tag';
const DB_TABLE_GEOTAG = 'geotag';

if(isset($_REQUEST["tag"])){
	echo "[Program C] Input tag = [".$_REQUEST["tag"]."]<br>";

	$mysqli = new mysqli(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);
	if(is_null($mysqli)) {
		echo 'DB Error';
	}

	$sqlq1 = $mysqli->prepare('SELECT * FROM ' . DB_TABLE_TAG . ' WHERE tag like ?');
	$sqlq1->bind_param('s', $_REQUEST['tag']);
	$sqlq1->execute();

	$result = $sqlq1->get_result();

	$sqlq2 = $mysqli->prepare('SELECT * FROM ' . DB_TABLE_GEOTAG . ' WHERE id = ? ORDER BY time DESC');

	$cnt = 0;
	while($row = $result->fetch_assoc()) {
		$sqlq2->bind_param('i', $row['id']);
		$sqlq2->execute();
		$result2 = $sqlq2->get_result();

		while($row2 = $result2->fetch_assoc()) {
			echo "${row2['id']},\"${row2['time']}\",${row2['latitude']},${row2['longitude']},${row2['url']}<br>";
			++$cnt;
		}

		if($cnt >= 100) {
			break;
		}
	}
}else{
	echo "[Program C] Please input a tag.";
}
?>
	</body>
</html>
