#!/usr/bin/perl -T

my %p;
%p = @ARGV; s/,\z// foreach values %p; # DEPLOYMENT SCRIPT EDITS THIS LINE

use warnings;
use strict;
use Carp::Always;

use Tversky 'cat';

# ------------------------------------------------
# Parameters
# ------------------------------------------------

use constant NEWMAN_BLOCKS => 4;
use constant TRIALS_PER_NEWMAN_BLOCK => 3;

my %newman_options =
  (I => {prob => .5, amount => 4},
   D => {prob => .7, amount => 6});

# Waits are in milliseconds.
my $fixed_wait = 1_000;
my $median_rand_wait = 3_000;

sub block_appearance ($)
   {$_[0] % 2 ? 'newman-block-odd' : 'newman-block-even';}

sub describe_newman_option ($)
   {my $k = shift;
    sprintf '<b>%d%%</b> chance of <b>%d</b> cents',
        int(100 * $newman_options{$k}{prob}),
        $newman_options{$k}{amount};}

# ------------------------------------------------
# Declarations
# ------------------------------------------------

my $o; # Will be our Tversky object.

sub p ($)
   {"<p>$_[0]</p>"}

my $mean_rand_wait = $median_rand_wait / log(2);

sub rand_exp
# Get an exponentially distributed random variate.
   {my $mean = shift;
    $mean * -log(rand());}

# ------------------------------------------------
# Tasks
# ------------------------------------------------

sub newman_trial
   {my ($block, $trial, $appearance_class, $must_choose) = @_;

    my $k = sprintf 'b%02d.t%d', $block, $trial;
    my $wait = $o->save_once("newman.wait.$k", sub
       {$fixed_wait + int rand_exp $mean_rand_wait});
    $o->multiple_choice_page("newman.choice.$k",
        sprintf('<div class="newman-div %s">%s</div>',
            $appearance_class,
            sprintf '<p id="newman-header" class="newman-wait-%dms">%s</p>',
                $wait,
                'Choose A or wait for B to become available.'),
        PROC => sub 
           {# Accept I or D, and allow for the response time
            # (in ms) added by the JavaScript.
            /\A[ID] \d+\z/ ? $_ : undef},
        ['I', 'A'] => sprintf '<span id="newman-desc-I">%s</span><span id="newman-desc-D">%s</span>',
            describe_newman_option 'I',
            describe_newman_option 'D');
    $o->getu("newman.choice.$k") =~ /\A([ID])/ or die 'No ID match';
    my $choice = $1;
    my $won = $o->save_once("newman.won.$k", sub
       {rand() <= $newman_options{$choice}{prob}
          ? 1
          : ''});
    $o->okay_page("newman.outcome_page.$k", cat
        $won ? p 'WIN!' : '',
        p sprintf '%d cents', $won
          ? $newman_options{$choice}{amount}
          : 0);}

sub newman_task
   {#$o->okay_page('newman_task_instructions', p 'something something');

    foreach my $block (1 .. NEWMAN_BLOCKS)
      {foreach my $trial (1 .. TRIALS_PER_NEWMAN_BLOCK)
          {newman_trial $block, $trial, block_appearance($block), undef;}}}

# ------------------------------------------------
# Mainline code
# ------------------------------------------------

$o = new Tversky
   (cookie_name_suffix => 'Pattern',
    here_url => $p{here_url},
    database_path => $p{database_path},
    consent_path => $p{consent_path},
    task => $p{task},

    head => do {local $/; <DATA>},
    footer => "\n\n\n</body></html>\n",

    mturk => $p{mturk},
    assume_consent => $p{assume_consent});

$o->run(sub

   {newman_task;

    $o->buttons_page('gender',
        p 'Are you male or female?',
        'Male', 'Female');
    $o->nonneg_int_entry_page('age',
        p 'How old are you?');
    $o->multiple_choice_page('english',
        p 'Which of the following best describes your knowledge of English?',
        Native => 'I am a native speaker of English.',
        Fluent => 'I am <em>not</em> a native speaker of English, but I consider myself fluent.',
        Neither => 'I am not fluent in English.');});

__DATA__

<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title>Decision-Making</title>

<script type="text/javascript" src="newman.js"></script>

<style type="text/css">

    h1, form, div.expbody p
       {text-align: center;}

    div.expbody p.long
       {text-align: left;}

    input.consent_statement
       {border: thin solid black;
        background-color: white;
        color: black;
        margin-bottom: .5em;}

    div.multiple_choice_box
       {display: table;
        margin-left: auto; margin-right: auto;}
    div.multiple_choice_box > div.row
       {display: table-row;}
    div.multiple_choice_box > div.row > div
       {display: table-cell;}
    div.multiple_choice_box > div.row > div.button
       {padding-right: 1em;
        vertical-align: middle;}
    div.multiple_choice_box > div.row > .body
       {text-align: left;
        vertical-align: middle;}

    .newman-div
       {padding: 2em;
        border-width: 3mm;
        margin-bottom: 2em;}
    .newman-block-even
       {border-style: solid;}
    .newman-block-odd
       {border-style: dashed;}

    #newman-desc-D
       {display: none;}

    input.text_entry, textarea.text_entry
       {border: thin solid black;
        background-color: white;
        color: black;}

</style>
