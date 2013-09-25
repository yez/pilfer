Pilfer = function(){
  this.download_el = $('.download');
  this.form = $('.pilfer-form');
  this.spinner = $('.spinner');
  this.error_text = $('.invalid-url');
};

Pilfer.prototype.fileToDownload = function(jsonResponse){
  if(jsonResponse.success == true){
    this.download_el.prepend(jsonResponse.file);
  }
  else{
    this.error_text.show();
  }
}

Pilfer.prototype.showSpinner = function(jsonResponse){
  this.form.hide();
  this.error_text.hide();
  this.spinner.show();
}

Pilfer.prototype.hideSpinner = function(jsonResponse){
  this.spinner.hide();
  this.form.show();
}
