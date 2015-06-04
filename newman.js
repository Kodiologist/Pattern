'use strict';

window.onload = function() {

var $ = function(x) {return document.getElementById(x)};

var timeout_frontend = 300;
var timeout = function(duration, callback)
// Call the callback after at least 'duration' seconds.
// http://www.sitepoint.com/creating-accurate-timers-in-javascript
//   {window.setTimeout(callback, duration);}
   {var f = function()
       {var elapsed = (new Date()).getTime() - start;
        if (elapsed < duration)
            window.setTimeout(f, Math.max(0, duration - elapsed));
        else
            callback();}
    var start = (new Date()).getTime();
    window.setTimeout(f, Math.max(0, duration - timeout_frontend));};

var header = $('newman-header');
if (header)
 // This page is a choice page for the Newman task.

   {var cls_matches = /^newman-dwait-(\d+)ms newman-must-choose-(\w+)/.exec(header.className);
    var dwait = parseInt(cls_matches[1], 10);
    var must_choose = cls_matches[2];

    var button_i = $('multiple_choice.I');
    var button_d = $('multiple_choice.D');

    var start_time = (new Date()).getTime();

    // Make D available after the dwait timeout.
    timeout(dwait, function()
       {if (must_choose !== 'I')
            button_d.disabled = false;
        button_d.textContent = 'B';});

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

   {// If there's an ITI, enable the button once it's over.

    var iti = parseInt(/^newman-iti-(\d+)ms/.exec(outcome_div.className)[1], 10);
    var button = document.getElementsByTagName('button')[0];
    if (button.disabled)
       {timeout(iti, function()
           {button.disabled = false;
            button.textContent = 'Next';});}

    return;}

};
