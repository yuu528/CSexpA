<!DOCTYPE html>
<html lang="ja">
	<head>
		<title>実装Ａの結果</title>
	</head>
	<body>
		<?php
			set_time_limit(0);

			if(isset($_REQUEST["tag"])) {
				echo "[Program A] Input tag = [".$_REQUEST["tag"]."]<br>";

				$ids = [];

				// Search ids by tag
				$fp = @fopen('tag.csv', 'r');

				if($fp) {
					while(($buf = fgets($fp)) !== false) {
						$line_arr = explode(',', $buf);

						if(rtrim($line_arr[1]) == $_REQUEST['tag']) {
							$ids[] = $line_arr[0];
						}
					}

					fclose($fp);
				}

				// Search geotag data by id
				$fp = @fopen('geotag.csv', 'r');

				$data = [];

				if($fp) {
					while(($buf = fgets($fp)) !== false) {
						$line_arr = explode(',', $buf);

						if(in_array($line_arr[0], $ids)) {
							$data[] = [
								'id' => $line_arr[0],
								'date' => $line_arr[1],
								'lat' => $line_arr[2],
								'lon' => $line_arr[3],
								'url' => $line_arr[4]
							];
						}
					}
				}

				// Sort by date
				usort($data, function($a, $b) {
					return $a['date'] < $b['date'] ? 1 : -1;
				});

				// Output
				$cnt = 0;
				foreach($data as $d) {
					echo "${d['id']},${d['date']},${d['lat']},${d['lon']},${d['url']}<br>";
					if(++$cnt === 100) break;
				}
			} else {
				echo "[Program A] Please input a tag.";
			}
		?>
	</body>
</html>
