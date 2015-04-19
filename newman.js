'use strict';

window.onload = function() {

var $ = function(x) {return document.getElementById(x)};

var header = $('newman-header');
if (!header)
 // This page isn't a Newman-task page.
    return;

var button = $('multiple_choice.I');

var cls_matches = /^newman-iti-(\d+)ms newman-dwait-(\d+)ms newman-must-choose-(\w+)/.exec(header.className);
var iti = parseInt(cls_matches[1], 10);
var dwait = parseInt(cls_matches[2], 10);
var must_choose = cls_matches[3];

// If must_choose is D, disable I.
if (must_choose === 'D')
    button.disabled = true;

// Start the trial after the ITI.
var after_iti_f = function()
   {$('newman-iti').style.display = 'none';
    $('newman-div').style.display = 'block';
    $('newman-fields').style.display = 'block';

    // If must_choose is not I, make D available after the dwait timeout.
    if (must_choose !== 'I')
       {var after_dwait_f = function()
           {button.setAttribute('value', 'D');
            button.textContent = 'B';
            button.disabled = false;
            $('newman-desc-I').style.display = 'none';
            $('newman-desc-D').style.display = 'inline';
            header.textContent = 'B is now available.';};
        window.setTimeout(after_dwait_f, dwait);}

    // When the subject submits the form, include the response time.
    var start_time = (new Date()).getTime();
    document.forms[0].onsubmit = function()
       {var old_val = button.getAttribute('value');
        var response_time = (new Date()).getTime() - start_time;
        button.setAttribute('value', old_val + ' ' + response_time);
        return true;};}
if (iti)
    window.setTimeout(after_iti_f, iti);
else
    after_iti_f();

};
