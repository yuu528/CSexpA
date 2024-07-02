<?php
// constants
const GET_QUERY = 'query';
const GET_PAGE = 'page';

const DATA_RESULTS = 'results';
const DATA_COUNT = 'count';
const DATA_PER_PAGE = 'perPage';
const DATA_PAGE = 'page';

const DB_HOST = 'localhost';
const DB_USER = 'pi';
const DB_PASSWORD = 'csexpatestpassword';
const DB_NAME = 'CSexp1DB';
const DB_TABLE = 'zipJapan';

const RESULTS_PER_PAGE = 10;

function reply($data) {
	header('Content-Type: application/json');
	echo json_encode($data);
	exit();
}

$data = [
	'results' => [
	]
];

// parse params
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

if(array_key_exists(GET_PAGE, $_GET) && is_numeric($_GET[GET_PAGE])) {
	$page = intval($_GET[GET_PAGE]);
} else {
	$page = 1;
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
$from_row = RESULTS_PER_PAGE * ($page - 1);
$to_row = RESULTS_PER_PAGE;

// get result
$sqlq = $mysqli->prepare('SELECT * FROM ' . DB_TABLE . " $q_where LIMIT ?, ?");
$sqlq->bind_param('sii', $query_like, $from_row, $to_row);
$sqlq->execute();
$result = $sqlq->get_result();

$sqlq->close();

// count all result
$sqlq_count = $mysqli->prepare('SELECT count(*) FROM ' . DB_TABLE . " $q_where");
$sqlq_count->bind_param('s', $query_like);

$sqlq_count->execute();
$result_count = $sqlq_count->get_result();
$data[DATA_COUNT] = $result_count->fetch_row()[0];
$data[DATA_PER_PAGE] = RESULTS_PER_PAGE;
$data[DATA_PAGE] = $page;

$sqlq_count->close();

while(!is_null($row = $result->fetch_assoc()) && $row !== false) {
	array_push($data[DATA_RESULTS], $row);
}

reply($data);
?>
