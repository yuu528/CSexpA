document.addEventListener('DOMContentLoaded', () => {
	const btn = document.getElementById('btn-submit');
	const form = document.getElementById('form');

	btn.addEventListener('click', e => {
		form.submit();

		return false;
	});

	const frame = document.getElementById('frame');
	frame.addEventListener('load', e => {
		frame.setAttribute('height', frame.contentWindow.document.documentElement.scrollHeight);
	});

	const input = document.getElementById('input-query');

	M.Autocomplete.init(document.querySelectorAll('.autocomplete'), {data: {}});
	const acInstance = M.Autocomplete.getInstance(input);

	const xhr = new XMLHttpRequest();
	let toId = null;

	xhr.addEventListener('load', e => {
		if(xhr.status === 200) {
			try {
				const data = JSON.parse(xhr.responseText);
				let results = {};

				if('results' in data) {
					data.results.forEach(item => {
						results[item.addr1 + item.addr2 + item.addr3] = null;
					});

					acInstance.updateData(results);
					acInstance.open();
				} else {
					acInstance.updateData({});
				}
			} catch(e) {
				console.error(e);
			}
		}
	});

	input.addEventListener('keyup', e => {
		clearTimeout(toId);
		toId = setTimeout(() => {
			xhr.abort();
			xhr.open('GET', `suggest.php?query=${input.value}`);
			xhr.send();
		});
	});
});
