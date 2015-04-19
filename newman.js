'use strict';

window.onload = function() {

var $ = function(x) {return document.getElementById(x)};

var header = $('newman-header');
if (!header)
 // This page isn't a Newman-task page.
    return;

var button = $('multiple_choice.I');

// After the wait timeout, make B available.
var wait_duration = parseInt(
    /^newman-wait-([0-9]+)ms/.exec(header.className)[1],
    10);
var after_wait_f = function()
   {button.setAttribute('value', 'D');
    button.textContent = 'B';
    $('newman-desc-I').style.display = 'none';
    $('newman-desc-D').style.display = 'inline';
    header.textContent = 'B is now available.';};
window.setTimeout(after_wait_f, wait_duration);

// When the subject submits the form, include the response time.
var start_time = (new Date()).getTime();
document.forms[0].onsubmit = function()
   {var old_val = button.getAttribute('value');
    var response_time = (new Date()).getTime() - start_time;
    button.setAttribute('value', old_val + ' ' + response_time);
    return true;};

};
