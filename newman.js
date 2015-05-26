'use strict';

window.onload = function() {

var $ = function(x) {return document.getElementById(x)};

var header = $('newman-header');
if (!header)
 // This page isn't a Newman-task page.
    return;

var button_i = $('multiple_choice.I');
var button_d = $('multiple_choice.D');

var cls_matches = /^newman-iti-(\d+)ms newman-dwait-(\d+)ms newman-must-choose-(\w+)/.exec(header.className);
var iti = parseInt(cls_matches[1], 10);
var dwait = parseInt(cls_matches[2], 10);
var must_choose = cls_matches[3];

// D starts out unavailable.
button_d.disabled = true;
button_d.textContent = '[Not available yet]';

// If must_choose is D or I, forbid the other.
if (must_choose === 'I')
   {button_d.disabled = true;
    $('newman-desc-D').className += ' newman-desc-forbidden';}
else if (must_choose === 'D')
   {button_i.disabled = true;
    $('newman-desc-I').className += ' newman-desc-forbidden';}

// Start the trial after the ITI.
var after_iti_f = function()
   {$('newman-iti').style.display = 'none';
    $('newman-div').style.display = 'block';
    $('newman-fields').style.display = 'block';

    // Make D available after the dwait timeout.
    var after_dwait_f = function()
       {if (must_choose !== 'I')
            button_d.disabled = false;
        button_d.textContent = 'B';
        header.textContent = 'B is now available.';};
    window.setTimeout(after_dwait_f, dwait);

    // When the subject submits the form, include the response time.
    var start_time = (new Date()).getTime();
    document.forms[0].onsubmit = function()
       {var response_time = (new Date()).getTime() - start_time;
        for (var i = 0 ; i < 2 ; ++i)
           {var button = i ? button_i : button_d;
            var old_val = button.getAttribute('value');
            button.setAttribute('value', old_val + ' ' + response_time);}
        return true;};}
if (iti)
    window.setTimeout(after_iti_f, iti);
else
    after_iti_f();

};
