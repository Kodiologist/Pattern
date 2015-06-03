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

my $newman_blocks = 14;
my $trials_per_newman_block = 3;
  # The instructions implicitly assume that
  # $trials_per_newman_block is 3.

my %newman_options =
  (I => {prob => .5, amount => 4},
   D => {prob => .7, amount => 6});

# Waits are in milliseconds.
my $fixed_dwait = 5_000;
my $median_rand_dwait = 5_000;

# ------------------------------------------------
# Declarations
# ------------------------------------------------

my $o; # Will be our Tversky object.

sub p ($)
   {"<p>$_[0]</p>"}
sub pl ($)
   {"<p class='long'>$_[0]</p>"}

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
    defined $trial
      ? sprintf 'newman.task.%s.b%02d.t%d', $kind, $block, $trial
      : sprintf 'newman.task.%s.b%02d', $kind, $block}

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

sub describe_newman_option ($)
   {my $k = shift;
    my $prob = $newman_options{$k}{prob};
    my $amount = $newman_options{$k}{amount};
    my $desc = sprintf "<b>%d%%</b> chance of <b>%d</b> cents",
        int(100 * $prob), $amount;
    my $bar = sprintf '<span class="%s"><span class="%s" style="height: %d%%"></span></span>',
        'newman-probability-bar',
        'bad-outcome',
        int(100 * (1 - $prob));
    cat $desc, $bar, "$amount cents";}

sub k ($);
sub newman_div;
sub newman_trial
   {my ($block, $trial, $appearance_class, $must_choose) = @_;
    in($must_choose, qw(I D either always_either))
        or die "Unknown \$must_choose: $must_choose";

    local *k = sub {mk_newman_key $_[0], $block, $trial};
    local *newman_div = sub {sprintf
        '<div class="newman-div %s">%s</div>',
        $appearance_class,
        $_[0]};

    my $dwait = $o->save_once(k 'dwait', sub
       {$fixed_dwait + int rand_exp $mean_rand_dwait});

    $o->multiple_choice_page(k 'choice',

        newman_div(sprintf '<p id="newman-header" class="newman-dwait-%dms newman-must-choose-%s">%s</p>',
            $dwait,
            $must_choose,
            sprintf 'On this trial, you %s.',
                $must_choose eq 'I'
              ? 'must choose A'
              : $must_choose eq 'D'
              ? 'must choose B'
              : 'may choose either A or B'),

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
    # If the subject chose I, enforce an inter-trial interval
    # $iti of the same duration they would've waited for D.
    my $iti = max 0, $dwait - get_newman_rt $block, $trial;
    $o->okay_page(k 'outcome_page',
        newman_div(($won ? p 'WIN!' : '') . p(sprintf '%d cents', $won
          ? $newman_options{$choice}{amount}
          : 0)),
        fields_wrapper => "<div id='newman-outcome' class='newman-iti-${iti}ms'>%s</div>");}

my $newman_example = sprintf(
    '<div id="newman-fields"><div class="multiple_choice_box">%s%s</div></div>',
    sprintf('<div class="row"><p>A</p>%s</div>', describe_newman_option 'I'),
    sprintf('<div class="row"><p>B</p>%s</div>', describe_newman_option 'D'));

sub newman_task_instructions
   {my $condition = shift;

    # General instructions for the Newman task.
    $o->okay_page('newman.warnings', cat
        pl 'Some quick notes before we begin:',
        sprintf '<ul>%s</ul>', cat map {"<li>$_</li>"}
            q{Please give the experiment your undivided attention. You'll have enough time to complete the HIT if you don't multitask or walk away mid-experiment.},
            q{This experiment uses timers to make you wait for certain things. Don't use your browser's back button or refresh button on a page with a timer, or the timer may restart (in which case it will have the same length as before).});
    $o->okay_page('newman.general_instructions', cat
        pl q{In this HIT, you'll complete a number of trials which will allow you to choose between two gambles, A or B. Money you win from the gambles will be given to you after the HIT as a bonus. You can't lose money from gambles. Right after you choose each gamble, I'll tell you whether or not you won the gamble.},
        pl q{Here's what the gambles look like:},
        $newman_example,
        pl q{The colored bars are just graphical representations of the chance of winning.},
        pl q{Notice that B has both a higher chance of paying out and a bigger payout. However, B isn't immediately available at the beginning of each trial. It will show as "[Not available yet]". You'll have to wait a random, unpredicatable amount of time (sometimes short, sometimes long) for B to become available.},
        pl q{Choosing A will allow you to receive an outcome (either winning or not winning) without waiting, because A is available from the start of each trial. But choosing A won't let you complete the HIT any faster, because the time you <strong>would have</strong> waited for B, had you waited for it, will be added to the time you have to wait to get to the next trial (or to the end of the HIT). Any time you spent waiting before choosing A (although you don't <strong>need</strong> to wait before choosing A, as you do for B) will be credited towards reducing this wait.});

    # The quiz
    foreach (
            {k => 'better_amount',
                body => cat(
                    p q{Let's test your understanding.},
                    p 'Which option has the bigger payout?'),
                choices => ['A', 'B', 'They have the same payout'],
                correct => 'B'},
            {k => 'better_prob',
                body => p q{Compared to B, A's chance of paying out is},
                choices => ['lower', 'higher', 'the same'],
                correct => 'lower'},
            {k => 'immediate',
                body => p q{Which option can you choose as soon as a trial starts?},
                choices => ['A', 'B', 'Either A or B'],
                correct => 'A'},
            {k => 'faster_completion',
                body => p q{Which option will allow you to complete the HIT faster?},
                choices => ['A', 'B', q{Neither; it makes no difference}],
                correct => q{Neither; it makes no difference}})
       {my %h = %$_;
        $o->buttons_page("newman.quiz.question.$h{k}",
            $newman_example . $h{body},
            @{$h{choices}});
        my $response = $o->getu("newman.quiz.question.$h{k}");
        $o->okay_page("newman.quiz.feedback.$h{k}", p(
            $response eq $h{correct}
              ? 'Correct.'
              : "Nope, the correct answer was: <strong>$h{correct}</strong>."));}

    # Condition-specific instructions.
    $o->okay_page('newman.block_types', cat
       pl 'Okay, one more thing before we begin.',
       pl qq{You'll complete trials in blocks of $trials_per_newman_block.},
       sprintf('<div class="newman-div %s">%s</div>',
           'newman-block-odd',
           q{In <strong>odd</strong>-numbered blocks (the 1st, 3rd, 5th, and so on), you'll see this background.}),
       sprintf('<div class="newman-div %s">%s</div>',
           'newman-block-even',
           q{In <strong>even</strong>-numbered blocks (the 2nd, 4th, 6th, and so on), you'll see this background.}),
       pl($condition eq 'control'
          ? q{The task works the same whether you're in an odd block or an even block.}
          : $condition eq 'within_pattern'
          ? q{Within each block, whether even or odd, you can choose either A or B on trial 1, but the task will force you to repeat that choice on trial 2 and trial 3.}
          : $condition eq 'across_pattern'
          ? q{In <strong>odd</strong> blocks, you can choose either A or B. In <strong>even</strong> blocks, the task will force you to repeat the series of choices you made in the previous block. So if in the 1st block you chose A, then B, then A, the task will force you in the 2nd block to choose A, then B, then A.}
          : $condition eq 'across_force_d'
          ? q{In <strong>odd</strong> blocks, you can choose either A or B. In <strong>even</strong> blocks, the task will force you choose B on every trial.}
          : die "Unknown \$condition: $condition"),
       $condition eq 'control' ? '' :
          pl q{You'll see a quick reminder of the rules before each block.});}

sub newman_task
   {my $condition = shift;

    newman_task_instructions $condition;

    my $a_or_b = 'you may choose either A or B';

    foreach my $block (1 .. $newman_blocks)
       {my $even_block = $block % 2 == 0;
        $o->okay_page(mk_newman_key('instructions', $block),
            p sprintf 'In the next block of %s trials, %s.', $trials_per_newman_block,
                $condition eq 'control'
              ? $a_or_b
              : $condition eq 'within_pattern'
              ? "$a_or_b on trial 1, but you'll have to repeat that choice on trial 2 and trial 3"
              : $condition eq 'across_pattern'
              ? $even_block
                ? q[you'll have to repeat the choices you made in the previous block]
                : "$a_or_b. In the block after that, you'll have to repeat these choices"
              : $condition eq 'across_force_d'
              ? $even_block
                ? q[you'll have to choose B]
                : $a_or_b
              : die "Unknown \$condition: $condition");
        foreach my $trial (1 .. $trials_per_newman_block)
           {newman_trial $block, $trial, $block % 2 ? 'newman-block-odd' : 'newman-block-even',
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

    .newman-div
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
        margin-right: 0;
        text-align: center;}
    #newman-fields .row
       {width: 50%;
        display: table-cell;}
    #newman-fields .row > div
       {display: block;}
    #newman-fields .button
       {padding: 0;}

    .newman-desc-forbidden
       {text-decoration: line-through;}

    .newman-probability-bar
       {margin-top: 2em;
        display: block;
        width: 3em;
        height: 6em;
        margin-left: auto;
        margin-right: auto;
        background-color: #00cc00;}
    .newman-probability-bar .bad-outcome
       {display: block;
        width: 100%;
        background-color: #aa0000;
        border-bottom: medium solid black;}

    input.text_entry, textarea.text_entry
       {border: thin solid black;
        background-color: white;
        color: black;}

</style>
