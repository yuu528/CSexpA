<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8">
		<title>ZipSearch</title>
	</head>
	<body>
<?php
ini_set('display_errors', '1');

// constants
const GET_QUERY = 'query';
const GET_PAGE = 'page';

const DB_HOST = 'localhost';
const DB_USER = 'pi';
const DB_PASSWORD = 'csexpatestpassword';
const DB_NAME = 'CSexp1DB';
const DB_TABLE = 'zipShizuoka';

const RESULTS_PER_PAGE = 10;

const LANG_DEFAULT = 'ja';

const LANG_NO_QUERY = 'no_query';
const LANG_DB_CONNECTION_ERROR = 'db_connection_error';
const LANG_QUERY = 'query';
const LANG_PAGE = 'page';
const LANG_NINM = 'ninm';
const LANG_NO_PAGE = 'no_page';
const LANG_N_ALL = 'n_all';
const LANG_ZIP = 'zip';
const LANG_ADDR = 'addr';

function i18n($id) {
	// translations
	static $langs = [
		'ja' => [
			LANG_NO_QUERY => '検索値が指定されていません。',
			LANG_DB_CONNECTION_ERROR => 'データベース接続エラー。',
			LANG_QUERY => '検索値',
			LANG_PAGE => 'ページ',
			LANG_NINM => '%d 件中 %d 件',
			LANG_NO_PAGE => '指定されたページ番号のページはありません。',
			LANG_N_ALL => '全%d件',
			LANG_ZIP => '郵便番号',
			LANG_ADDR => '住所'
		]
	];

	return $langs[LANG_DEFAULT][$id];
}

function print_page_link($query, $page, $text) {
	echo '<a href="result.php?query=' . urlencode($query) . '&page=' . $page . '">' . $text . '</a> ';
}

// print a message as an error and exit
function print_error($msg) {
	echo $msg;
	exit();
}

// get params
if(array_key_exists(GET_QUERY, $_GET)) {
	// remove space and tab
	$query = str_replace(
		[' ', '\t'],
		'',
		$_GET[GET_QUERY]
	);
} else {
	print_error(i18n(LANG_NO_QUERY));
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

// check if query is kana
if(preg_match('/^[ァ-ヿ0-9()]+$/u', $query) === 1) {
	$sqlq = $mysqli->prepare('SELECT * FROM ' . DB_TABLE . ' WHERE CONCAT(kana1, kana2, kana3) LIKE ? ORDER BY zip');
} else {
	$sqlq = $mysqli->prepare('SELECT * FROM ' . DB_TABLE . ' WHERE CONCAT(addr1, addr2, addr3) LIKE ? ORDER BY zip');
}

$query_like = "%$query%";
$sqlq->bind_param('s', $query_like);

$sqlq->execute();
$result = $sqlq->get_result();

// echoback
echo i18n(LANG_QUERY) . ': ' . $query;
echo '<span style="display: inline-block; width: 2em;"></span>';
echo i18n(LANG_PAGE) . ': ' . $page;
echo '<br>';

printf(i18n(LANG_N_ALL), $result->num_rows);
echo '<br><br>';

$from_row = RESULTS_PER_PAGE * ($page - 1);

if($result->num_rows <= $from_row) {
	print_error(i18n(LANG_NO_PAGE));
}

$result->data_seek($from_row);

// print result table
// head
echo '<table><thead><tr>';
foreach([
	i18n(LANG_ADDR),
	i18n(LANG_ZIP)
] as $col) {
	echo "<th>$col</th>";
}

// body
echo '</tr></thead><tbody>';

$count = 0;
while(!is_null($row = $result->fetch_assoc()) && $row !== false && ++$count <= RESULTS_PER_PAGE) {
	// print address with ruby (kana)
	echo '<tr><td><ruby>';
	foreach([
		[ $row['addr1'], $row['kana1'] ],
		[ $row['addr2'], $row['kana2'] ],
		[ $row['addr3'], $row['kana3'] ]
	] as $addr) {
		echo "${addr[0]}<rt>${addr[1]}</rt>";
	}

	// print zip
	echo "</ruby></td><td>${row['zip']}</td></tr>";
}

echo '</tbody></table>';

$end_page = ceil($result->num_rows / RESULTS_PER_PAGE);

if(1 < $page) {
	print_page_link($query, $page - 1, '<');
}

for($i = 1; $i <= $end_page; $i++) {
	if($i === $page) {
		echo "$i ";
	} else {
		print_page_link($query, $i, $i);
	}
}

if($page < $end_page) {
	print_page_link($query, $page + 1, '>');
}
?>
	</body>
</html>
