<?php
// constants
const GET_QUERY = 'query';

const DB_HOST = 'localhost';
const DB_USER = 'pi';
const DB_PASSWORD = 'csexpatestpassword';
const DB_NAME = 'CSexp1DB';
const DB_TABLE = 'zipJapan';

const RESULT_LIMIT = 10;

function reply($data) {
	header('Content-Type: application/json');
	echo json_encode($data);
	exit();
}

$data = [
	'results' => [
	]
];

if(array_key_exists(GET_QUERY, $_GET)) {
	// remove space and tab
	$query = str_replace(
		[' ', '\t'],
		'',
		$_GET[GET_QUERY]
	);
} else {
	reply($data);
}

// connect to DB
$mysqli = new mysqli(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);
if(is_null($mysqli)) {
	print_error(i18n(LANG_DB_CONNECTION_ERROR));
}

$query_like = "%$query%";

if(is_numeric($query)) {
	$q_where = 'WHERE zip LIKE ?';
} elseif(preg_match('/^([0-9]*)-([0-9]*)$/', $query, $m) === 1 && count($m) == 3) {
	// 123-4567 -> 123-4567
	// 23-45 -> _23-45__
	$query_like = str_repeat('_', 3 - strlen($m[1])) . $m[1] . $m[2] . str_repeat('_', 4 - strlen($m[2]));
	$q_where = 'WHERE zip LIKE ?';
} elseif(preg_match('/^[ァ-ヿ0-9()]+$/u', $query) === 1) {
	$q_where = 'WHERE CONCAT(kana1, kana2, kana3) LIKE ?';
} else {
	$q_where = 'WHERE CONCAT(addr1, addr2, addr3) LIKE ?';
}

// set limits
$limit = RESULT_LIMIT;

$sqlq = $mysqli->prepare('SELECT * FROM ' . DB_TABLE . " $q_where LIMIT ?");

$sqlq->bind_param('si', $query_like, $limit);

// get result
$sqlq->execute();
$result = $sqlq->get_result();

while(!is_null($row = $result->fetch_assoc()) && $row !== false) {
	array_push($data['results'], $row);
}

reply($data);
?>
