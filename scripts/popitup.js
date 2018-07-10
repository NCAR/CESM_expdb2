function popitup(url,dim) {
	newwindow=window.open(url,'',dim);
	if (window.focus) {newwindow.focus()}
	return false;
}
