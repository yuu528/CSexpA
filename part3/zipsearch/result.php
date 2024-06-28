<!DOCTYPE html>
<html>
	<head>
		<title>ZipSearch 検索結果</title>

		<meta charset="utf-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0"/>

		<!-- Materialize -->
		<link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
		<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/css/materialize.min.css">

		<link rel="stylesheet" href="style.css">
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
		const DB_TABLE = 'zipJapan';

		const RESULTS_PER_PAGE = 10;

		const LANG_DEFAULT = 'ja';

		const LANG_NO_QUERY = 'no_query';
		const LANG_DB_CONNECTION_ERROR = 'db_connection_error';
		const LANG_QUERY = 'query';
		const LANG_PAGE = 'page';
		const LANG_NINM_PAGE = 'ninm_page';
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
					LANG_NINM_PAGE => '%d / %d ページ',
					LANG_NO_PAGE => '指定されたページ番号のページはありません。',
					LANG_N_ALL => '全%d件',
					LANG_ZIP => '郵便番号',
					LANG_ADDR => '住所'
				]
			];

			return $langs[LANG_DEFAULT][$id];
		}

		function print_page_link($query, $page, $text, $class = 'waves-effect') {
			echo '<li class="' . $class . '"><a href="result.php?query=' . urlencode($query) . '&page=' . $page . '">' . $text . '</a></li>';
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

		if($query === '') {
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

		// check if query is kana or zip
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

		$sqlq = $mysqli->prepare('SELECT * FROM ' . DB_TABLE . " $q_where LIMIT ?, ?");

		$sqlq->bind_param('sii', $query_like, $from_row, $to_row);

		// get result
		$sqlq->execute();
		$result = $sqlq->get_result();

		// count all result
		$sqlq_count = $mysqli->prepare('SELECT count(*) FROM ' . DB_TABLE . " $q_where");
		$sqlq_count->bind_param('s', $query_like);

		$sqlq_count->execute();
		$result_count = $sqlq_count->get_result();
		$count = $result_count->fetch_row()[0];
		$end_page = ceil($count / RESULTS_PER_PAGE);

		$sqlq_count->close();
		?>

		<!-- Result count -->
		<?php
		printf(i18n(LANG_N_ALL), $count);

		if($count <= $from_row || $from_row < 0) {
			echo '<br>';
			print_error(i18n(LANG_NO_PAGE));
		}
		?>
		<span style="display: inline-block; width: 2em;"></span>
		<?php
		printf(i18n(LANG_NINM_PAGE), $page, $end_page);
		?>

		<!-- Result table -->
		<table>
			<thead>
				<tr>
					<?php
					foreach([
						i18n(LANG_ADDR),
						i18n(LANG_ZIP)
					] as $col) {
						echo "<th>$col</th>";
					}
					?>
				</tr>
			</thead>
			<tbody>
				<?php
				while(!is_null($row = $result->fetch_assoc()) && $row !== false) {
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
					$intzip = strval($row['zip']);
					echo '</ruby></td><td>' . substr($intzip, 0, 3) . '-' . substr($intzip, -4, 4) . '</td></tr>';
				}

				$sqlq->close();
				$mysqli->close();
				?>
			</tbody>
		</table>

		<!-- Pagenation -->
		<ul class="pagination">
			<?php
			// prev
			if(1 < $page) {
				print_page_link($query, $page - 1, '<i class="material-icons">chevron_left</i>');
			} else {
				print_page_link($query, '', '<i class="material-icons">chevron_left</i>', 'disabled');
			}

			// pages
			for($i = 1; $i <= $end_page; $i++) {
				if($i === $page) {
					print_page_link($query, $i, $i, 'active');
				} else {
					print_page_link($query, $i, $i);
				}
			}

			// next
			if($page < $end_page) {
				print_page_link($query, $page + 1, '<i class="material-icons">chevron_right</i>');
			} else {
				print_page_link($query, '', '<i class="material-icons">chevron_right</i>', 'disabled');
			}
			?>
		</ul>

		<!-- Materialize -->
		<script src="https://cdnjs.cloudflare.com/ajax/libs/materialize/1.0.0/js/materialize.min.js"></script>
	</body>
</html>
