#!/usr/bin/perl -T

my %p;
%p = @ARGV; s/,\z// foreach values %p; # DEPLOYMENT SCRIPT EDITS THIS LINE

use warnings;
use strict;
use Carp::Always;

use List::Util 'max';
use Tversky 'cat';

# ------------------------------------------------
# Parameters
# ------------------------------------------------

use constant NEWMAN_BLOCKS => 14;
use constant TRIALS_PER_NEWMAN_BLOCK => 3;

my %newman_options =
  (I => {prob => .5, amount => 4},
   D => {prob => .7, amount => 6});

# Waits are in milliseconds.
my $fixed_dwait = 5_000;
my $median_rand_dwait = 5_000;

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

my $mean_rand_dwait = $median_rand_dwait / log(2);

sub rand_exp
# Get an exponentially distributed random variate.
   {my $mean = shift;
    $mean * -log(rand());}

sub in
 {my $item = shift;
  $item eq $_ and return 1 foreach @_;
  return 0;}

# ------------------------------------------------
# Tasks
# ------------------------------------------------

sub mk_newman_key
   {my ($kind, $block, $trial) = @_;
    sprintf 'newman.%s.b%02d.t%d', $kind, $block, $trial;}

sub get_newman_choice
# Returns 'I' or 'D'.
   {my ($block, $trial) = @_;
    $o->getu(mk_newman_key 'choice', $block, $trial) =~ /\A([ID])/
        or die 'No ID match';
    $1;}

sub get_newman_rt
# Returns the response time in ms.
   {my ($block, $trial) = @_;
    $o->getu(mk_newman_key 'choice', $block, $trial) =~ /\A[ID] (\d+)/
        or die 'No RT match';
    $1;}

sub k ($);
sub k_prev($);
sub newman_trial
   {my ($block, $trial, $appearance_class, $must_choose) = @_;
    in($must_choose, qw(I D either always_either))
        or die "Unknown \$must_choose: $must_choose";

    local *k = sub {mk_newman_key $_[0], $block, $trial};

    # If the subject chose I, enforce an inter-trial interval
    # $iti of the same duration they would've waited for D.
    my $iti = $block == 1 && $trial == 1 ? 0 : do
       {my $block_prev = $block - ($trial == 1);
        my $trial_prev = $trial == 1 ? TRIALS_PER_NEWMAN_BLOCK : $trial - 1;
        if (get_newman_choice($block_prev, $trial_prev) eq 'I')
          {my $prev_dwait = $o->getu(mk_newman_key 'dwait', $block_prev, $trial_prev);
           my $prev_rt = get_newman_rt $block_prev, $trial_prev;
           max 0, $prev_dwait - $prev_rt}
        else
          {0}};

    my $dwait = $o->save_once(k 'dwait', sub
       {$fixed_dwait + int rand_exp $mean_rand_dwait});

    $o->multiple_choice_page(k 'choice',

        sprintf('<p id="newman-iti">%s</p><div id="newman-div" class="%s">%s</div>',
            'Wait for the next trial to begin.',
            $appearance_class,
            sprintf '<p id="newman-header" class="newman-iti-%dms newman-dwait-%dms newman-must-choose-%s">%s</p>%s',
                $iti,
                $dwait,
                $must_choose,
                'Choose A or wait for B to become available.',
                !defined($must_choose) ? '' : sprintf '<p>On this trial, you %s.</p>',
                    $must_choose eq 'I'
                  ? 'must choose A'
                  : $must_choose eq 'D'
                  ? 'must choose B'
                  : 'may choose either of A or B'),

        PAGE => {
            fields_wrapper => '<div id="newman-fields">%s</div>',
            proc => sub
               {# Accept I or D depending on $must_choose, and allow
                # for the response time (in ms) added by the
                # JavaScript.
                my $re =
                    $must_choose eq 'I' ? 'I'
                  : $must_choose eq 'D' ? 'D'
                  :                       '[ID]';
                /\A$re \d+\z/ ? $_ : undef}},

        ['I', 'A'] => sprintf('<span id="newman-desc-I">%s</span>',
            describe_newman_option 'I'),
        ['D', 'B'] => sprintf('<span id="newman-desc-D">%s</span>',
            describe_newman_option 'D'));

    my $choice = get_newman_choice $block, $trial;
    my $won = $o->save_once(k 'won', sub
       {rand() <= $newman_options{$choice}{prob}
          ? 1
          : ''});
    $o->okay_page(k 'outcome_page', cat
        $won ? p 'WIN!' : '',
        p sprintf '%d cents', $won
          ? $newman_options{$choice}{amount}
          : 0);}

sub newman_task
   {my $condition = shift;

    #$o->okay_page('newman_task_instructions', p 'something something');

    foreach my $block (1 .. NEWMAN_BLOCKS)
       {my $even_block = $block % 2 == 0;
        foreach my $trial (1 .. TRIALS_PER_NEWMAN_BLOCK)
           {newman_trial $block, $trial, block_appearance($block),
              # What choice is the subject forced to make, if any?
                $condition eq 'control'
              ? 'always_either'
              : $condition eq 'within_pattern'
              ? $trial == 1
                  ? 'either'
                  : get_newman_choice($block, 1)
              : $condition eq 'across_pattern'
              ? $even_block
                  ? get_newman_choice($block - 1, $trial)
                  : 'either'
              : $condition eq 'across_force_d'
              ? $even_block
                  ? 'D'
                  : 'either'
              : die "Unknown \$condition: $condition";}}}

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

   {#newman_task 'control';
    #newman_task 'across_force_d';
    #newman_task 'within_pattern';
    newman_task 'across_pattern';

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

    #newman-div, #newman-fields
      /* These are revealed by JavaScript. */
       {display: none;}

    #newman-div
       {padding: 2em;
        border-width: 3mm;
        margin-bottom: 2em;
        color: black;}
    .newman-block-even
       {border-style: solid;
        background-color: #ffa;}
    .newman-block-odd
       {border-style: dashed;
        background-color: #aff;}

    #newman-fields .multiple_choice_box
       {width: 100%;
        margin-left: 0;
        margin-right: 0;}
    #newman-fields .row
       {width: 50%;
        display: table-cell;}
    #newman-fields .row > div
       {display: block;}

    .newman-desc-forbidden
       {text-decoration: line-through;}

    input.text_entry, textarea.text_entry
       {border: thin solid black;
        background-color: white;
        color: black;}

</style>
