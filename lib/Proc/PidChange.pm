package Proc::PidChange;

# ABSTRACT: a very cool module
# VERSION
# AUTHORITY

use strict;
use warnings;
use parent 'Exporter';

### Export setup
our @EXPORT      = 'check_current_pid';
our @EXPORT_OK   = qw( check_current_pid register_pid_change_callback unregister_pid_change_callback );
our %EXPORT_TAGS = (
  all      => \@EXPORT_OK,
  registry => [qw(register_pid_change_callback unregister_pid_change_callback)],
);


{
  ### Our state
  our $last_checked_pid;
  BEGIN { $last_checked_pid = $$ }

  our @callbacks;

  ### Check for pid changes
  sub check_current_pid {
    return if $last_checked_pid == $$;
    return _call_all_callbacks();
  }

  sub _call_all_callbacks {
    $_->() for @callbacks;
    return;
  }

  ### Callback registry API
  sub register_pid_change_callback {
    push @callbacks, grep { ref($_) eq 'CODE' } @_;
    return;
  }

  sub unregister_pid_change_callback {
    my %targets = map { $_ => 1 } grep { ref($_) eq 'CODE' } @_;
    @callbacks = grep { !$targets{$_} } @callbacks;

    return;
  }
}


1;
