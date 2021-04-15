// Custom JS for the admin area


let params;
window.CMS.wysiwyg = function() {
  let csrf_param;
  const csrf_token = $('meta[name=csrf-token]').attr('content');
  return csrf_param = $('meta[name=csrf-param]').attr('content');
};

if ((csrf_param !== undefined) && (csrf_token !== undefined)) {
  params = csrf_param + "=" + encodeURIComponent(csrf_token);
}

$('textarea.rich-text-editor, textarea[data-cms-rich-text]').redactor({
  deniedTags: [],
  formatting: ['p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'],
  plugins: ['imagemanager', 'filemanager', 'table', 'video', 'definedlinks'],
  lang: CMS.locale,
  replaceDivs: false
});