function appendOutput(cls, text) {
    $('#console-output').append('<pre class="' + cls + '">' + text + '</pre>');
    $('#line').focus();
}