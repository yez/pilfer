Pilfer = function(){
  this.download_el = $('.download');
  this.download_button = $('.pilfer-form input[type=submit]');
  this.spinner = $('.spinner');
};

Pilfer.prototype.fileToDownload = function(jsonResponse){
  this.download_el.html(jsonResponse.file);
}

Pilfer.prototype.showSpinner = function(jsonResponse){
  this.download_button.hide();
  this.spinner.show();
}

Pilfer.prototype.hideSpinner = function(jsonResponse){
  this.spinner.hide();
  this.download_button.show();
}
