'use strict';

window.onload = function() {

var $ = function(x) {return document.getElementById(x)};

var header = $('newman-header');
if (header)
 // This page is a choice page for the Newman task.

   {var cls_matches = /^newman-dwait-(\d+)ms newman-must-choose-(\w+)/.exec(header.className);
    var dwait = parseInt(cls_matches[1], 10);
    var must_choose = cls_matches[2];

    var button_i = $('multiple_choice.I');
    var button_d = $('multiple_choice.D');

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

    // Make D available after the dwait timeout.
    var after_dwait_f = function()
       {if (must_choose !== 'I')
            button_d.disabled = false;
        button_d.textContent = 'B';};
    window.setTimeout(after_dwait_f, dwait);

    // When the subject submits the form, include the response time.
    var start_time = (new Date()).getTime();
    document.forms[0].onsubmit = function()
       {var response_time = (new Date()).getTime() - start_time;
        for (var i = 0 ; i < 2 ; ++i)
           {var button = i ? button_i : button_d;
            var old_val = button.getAttribute('value');
            button.setAttribute('value', old_val + ' ' + response_time);}
        return true;}

    return;}

var outcome_div = $('newman-outcome');
if (outcome_div)
  // This page is an outcome page for the Newman task.

   {// If there's an ITI, disable the button until it's over.

    var iti = parseInt(/^newman-iti-(\d+)ms/.exec(outcome_div.className)[1], 10);
    if (iti)
       {var button = document.getElementsByTagName('button')[0];
        var old_textContent = button.textContent;
        button.disabled = true;
        button.textContent = '[Wait for next trial]';
        var after_iti_f = function()
            {button.disabled = false;
             button.textContent = old_textContent;}
        window.setTimeout(after_iti_f, iti);}

    return;}

};
