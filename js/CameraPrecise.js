
function CameraPrecise() {}

CameraPrecise.prototype.initialize = function(captureDeviceIndex, successCallback, errorCallback, options) {
	PhoneGap.exec("CameraPrecise.initialize", captureDeviceIndex, GetFunctionName(successCallback), GetFunctionName(errorCallback), options);
}

CameraPrecise.prototype.snap = function(successCallback) {
	PhoneGap.exec("CameraPrecise.snap", GetFunctionName(successCallback));
}

CameraPrecise.prototype.countSnapShots = function(successCallback) {
	PhoneGap.exec("CameraPrecise.countSnapShots", GetFunctionName(successCallback));
}


CameraPrecise.prototype.getSnapShot = function(index, successCallback, quality) {
	PhoneGap.exec("CameraPrecise.getSnapShot", index, GetFunctionName(successCallback), quality);
}

PhoneGap.addConstructor(function() {
	if(!window.plugins) {
		window.plugins = {};
	}
	window.plugins.cameraPrecise = new CameraPrecise();
});
