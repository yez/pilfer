Pilfer = function(){
  this.download_el = $('.download');
  this.download_button = $('.pilfer-form input[type=submit]');
  this.spinner = $('.spinner');
};

Pilfer.prototype.fileToDownload = function(jsonResponse){
  if(jsonResponse.success == true){
    this.download_el.html(jsonResponse.file);
  }
  else{
    this.download_el.html(jsonResponse.error);
  }

}

Pilfer.prototype.showSpinner = function(jsonResponse){
  this.download_el.html('');
  this.download_button.hide();
  this.spinner.show();
}

Pilfer.prototype.hideSpinner = function(jsonResponse){
  this.spinner.hide();
  this.download_button.show();
}
