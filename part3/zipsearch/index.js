window.onload = () => {
	const btn = document.getElementById('btn-submit');
	const form = document.getElementById('form');

	btn.addEventListener('click', e => {
		form.submit();
		form[0].reset();

		return false;
	});

	const frame = document.getElementById('frame');
	frame.addEventListener('load', e => {
		frame.setAttribute('height', frame.contentWindow.document.documentElement.scrollHeight);
	});
};
