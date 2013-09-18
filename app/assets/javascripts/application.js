//= require jquery
//= require jquery_ujs
//= require_tree .

$(document).ready(function(){
  var pilfer = new Pilfer();
  $(document).on('ajax:success', '.pilfer-form', function(e, data, status, xhr){
    pilfer.fileToDownload(data);
  });
});
