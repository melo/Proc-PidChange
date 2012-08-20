package Proc::PidChange;

# ABSTRACT: execute callbacks when PID changes
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

## Flag: if true, no need to pool for changes
our $RT = 0;
unless ($ENV{PROC_PIDCHANGE_NO_RT}) {
  eval {
    require POSIX::AtFork;
    POSIX::AtFork->import();
    POSIX::AtFork->add_to_child(\&check_current_pid);
    $RT++;
  };
}


### Our implementation
{
  ### Our state
  our $last_checked_pid;
  BEGIN { $last_checked_pid = $$ }

  our @callbacks;

  ### Check for pid changes
  sub check_current_pid {
    return if $last_checked_pid == $$;
    $last_checked_pid = $$;
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

=encoding utf8

=head1 SYNOPSIS

    use Proc::PidChange;

    ## check for pid changes
    check_current_pid();

    ## Registration of callbacks
    use Proc::PidChange ':all';

    register_pid_change_callback(sub { ... });


=head1 DESCRIPTION

This module provides a simple API to check if the process ID changed,
due to a fork() call. If such change is detected, it calls all the
registered callbacks.

The detection of PID changes can be done in two ways: in real-time as
soon as it changes, or by calling L</check_current_pid> on a regular
basis. The real-time version requires the L<POSIX::AtFork> module.

Interested parties should use the L</register_pid_change_callback> to
register a CodeRef to be called when the PID change is detected.


=head2 About real-time PID changes

Given that real-time is the most efficient method to detect PID changes,
we aggresively try to load L<POSIX::AtFork> module and if found, enable
real-time PID detection.

You can check to see if real-time detection is being used with the
C<$Proc::PidChange::RT> variable. If true, real-time detection is
available.

You can disable real-time detection by setting the
C<PROC_PIDCHANGE_NO_RT> environment to true before loading
L<Proc::PidChange>.


=head1 FUNCTIONS

=head2 check_current_pid

Check the current PID to see if it's changed. If yes, calls all
registered callbacks.


=head2 register_pid_change_callback

Register one or more callbacks to be called when the PID change
is detected.

If you register the same CodeRef callback twice, it will be
called twice.


=head2 unregister_pid_change_callback

Unregister one or more callbacks.

=cut
