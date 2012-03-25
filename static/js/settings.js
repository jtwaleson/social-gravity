function Settings() {
/* 
a setting object is to do the following:
{
	type: ['slider', 'checkbox'],
	default: [default value, i.e. true/false],
	key: [the key for this setting]

#slider specific:
	min: ..,
	max: ..,
	step: ..

}



*/
	var self = this;
	self.list = [];
	self.addSlider = function(min, max, default, id ) {
		self.list.push({type: slider, min: min, max: max, default: default, key: key}, 
	}
	self.reset = function() {
		for (var i in self.list) {
			self.list[i]['value'] = self.list[i]['default'];
		}
	}
}
