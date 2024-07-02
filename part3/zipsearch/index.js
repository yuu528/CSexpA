// Constants
const MAP_CENTER = [36, 137];

// Global
let map = null;
let markers = [];

document.addEventListener('DOMContentLoaded', () => {
	const btn = document.getElementById('btn-submit');
	const input = document.getElementById('input-query');

	btn.addEventListener('click', e => {
		btn.classList.add('disabled');
		if(input.value.length == 0) return;
		search(1);
		return;
	});

	// Setup autocompletion
	M.Autocomplete.init(document.querySelectorAll('.autocomplete'), {data: {}});
	const acInstance = M.Autocomplete.getInstance(input);

	const xhr = new XMLHttpRequest();

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
		xhr.abort();

		if(e.key === 'Enter') {
			search(1);
			acInstance.close();
		} else {
			xhr.open('GET', `result.php?query=${input.value}`);
			xhr.send();
		}
	});

	// Setup map
	map = L.map('map').setView(MAP_CENTER, 5);
	L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
		maxZoom: 19,
		attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
	}).addTo(map);
});

function zipToString(zip) {
	return zip.replace(/([0-9]{3})([0-9]{4})/, '$1-$2');
}

function search(page) {
	const input = document.getElementById('input-query');
	if(input.value.length == 0) return;

	const xhr = new XMLHttpRequest();
	xhr.addEventListener('load', e => {
		if(xhr.status === 200) {
			try {
				const data = JSON.parse(xhr.responseText);
				if(
					!'results' in data ||
					!'count' in data ||
					!'perPage' in data ||
					!'page' in data
				) return;

				// Add data to table
				const tBody = document.getElementById('table-result-body');
				tBody.innerText = '';

				data.results.forEach(datum => {
					/*
					 * <tbody>
					 *     <tr>
					 *         <td>
					 *              <ruby>
					 *                  {addr1} <rt>{kana1}</rt>
					 *                  ...
					 *              </ruby>
					 *         </td>
					 *     </tr>
					 * </tbody>
					 */
					const newTr = document.createElement('tr');
					const newTdAddr = document.createElement('td');
					const newTdZip = document.createElement('td');
					const newRuby = document.createElement('ruby');

					for(let i = 1; i <= 3; i++) {
						const newText = document.createTextNode(datum[`addr${i}`]);
						const newRt = document.createElement('rt');

						newRt.innerText = datum[`kana${i}`];

						newRuby.appendChild(newText);
						newRuby.appendChild(newRt);
					}

					newTdZip.innerText = zipToString(datum.zip.toString().padStart(7, '0'));

					newTdAddr.appendChild(newRuby);
					newTr.appendChild(newTdAddr);
					newTr.appendChild(newTdZip);
					tBody.appendChild(newTr);
				});

				const table = document.getElementById('table-result');
				table.style.display = 'table';

				// Show pagination
				const pageUl = document.getElementById('pagination');
				pageUl.innerText = '';

				const lastPage = Math.ceil(data.count / data.perPage);

				// prev btn
				const newLiPrev = document.createElement('li');
				const newAPrev = document.createElement('a');
				const newIPrev = document.createElement('i');

				// Materialize
				if(data.page <= 1) {
					newLiPrev.classList.add('disabled');
				}
				newIPrev.classList.add('material-icons');
				newIPrev.innerText = 'chevron_left';

				newAPrev.setAttribute('href', '#!');
				newAPrev.addEventListener('click', () => {
					search(data.page - 1);
				});

				newAPrev.appendChild(newIPrev);
				newLiPrev.appendChild(newAPrev);
				pageUl.appendChild(newLiPrev);

				// pages btn
				for(let i = 1; i <= lastPage; i++) {
					const newLi = document.createElement('li');
					const newA = document.createElement('a');

					// Materialize
					if(i === data.page) {
						newLi.classList.add('active');
					} else {
						newLi.classList.add('waves-effect');
					}

					newA.setAttribute('href', '#!');
					newA.innerText = i;
					newA.addEventListener('click', () => {
						search(i);
					});

					newLi.appendChild(newA);
					pageUl.appendChild(newLi);
				}

				// prev btn
				const newLiNext = document.createElement('li');
				const newANext = document.createElement('a');
				const newINext = document.createElement('i');

				// Materialize
				if(lastPage <= data.page) {
					newLiNext.classList.add('disabled');
				}
				newINext.classList.add('material-icons');
				newINext.innerText = 'chevron_right';

				newANext.setAttribute('href', '#!');
				newANext.addEventListener('click', () => {
					search(data.page + 1);
				});

				newANext.appendChild(newINext);
				newLiNext.appendChild(newANext);
				pageUl.appendChild(newLiNext);

				pageUl.style.display = 'block';

				// Update map
				updateMap(data.results.map(datum => datum.zip));
			} catch(e) {
				console.error(e);
			}
		}
	});

	xhr.open('GET', `result.php?query=${input.value}&page=${page}`);
	xhr.send();
}

function updateMap(zips) {
	const mapDiv = document.getElementById('map');
	const loadingMap = document.getElementById('loading-map');

	loadingMap.style.display = 'block';

	let maxLat = 0;
	let minLat = 90;
	let maxLon = 0;
	let minLon = 180;

	// remove markers
	markers.forEach(marker => {
		marker.remove();
	});
	markers = [];

	let i = 0;
	zips.map(zip =>
		zip.toString().padStart(7, '0')
	).forEach(zip => {
		const xhr = new XMLHttpRequest();
		xhr.addEventListener('load', e => {
			i++;
			if(zips.length <= i) {
				loadingMap.style.display = 'none';

				const btn = document.getElementById('btn-submit');
				btn.classList.remove('disabled');
			}

			if(xhr.status === 200) {
				try {
					const obj = JSON.parse(xhr.responseText);
					if(
						!'response' in obj ||
						!'location' in obj.response ||
						obj.response.location.length < 0
					) return;

					const data = obj.response.location[0];
					if(
						!'x' in data ||
						!'y' in data ||
						!'prefecture' in data ||
						!'city' in data ||
						!'town' in data ||
						!'postal' in data
					) return;

					let markerTexts = [
						'<b>' + zipToString(data.postal) + '</b>',
						[
							data.prefecture,
							data.city,
							data.town
						].join('')
					];

					const marker = L.marker([data.y, data.x]).addTo(map);
					marker.bindPopup(markerTexts.join('<br>'));
					markers.push(marker);

					maxLat = Math.max(maxLat, data.y);
					minLat = Math.min(minLat, data.y);
					maxLon = Math.max(maxLon, data.x);
					minLon = Math.min(minLon, data.x);

					mapDiv.style.display = 'block';
					map.invalidateSize(true);
					map.flyToBounds(
						[
							[minLat, minLon],
							[maxLat, maxLon]
						],
						{
							duration: 0.5,
							padding: [100, 100]
						}
					);
				} catch(e) {
					console.error(e);
				}
			}
		});

		xhr.open('GET', `https://geoapi.heartrails.com/api/json?method=searchByPostal&postal=${zip}`);
		xhr.send();
	});
}
