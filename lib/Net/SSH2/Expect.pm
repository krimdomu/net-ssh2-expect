#
# (c) 2011 Jan Gehring <jan.gehring@gmail.com>
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
#

=head1 NAME

Net::SSH2::Expect - An Expect like module for Net::SSH2

=head1 DESCRIPTION

This is a module to have expect like features for Net::SSH2. This is the first version of this module. Please report bugs at GitHub L<https://github.com/krimdomu/net-ssh2-expect>

=head1 DEPENDENCIES

=over 4

=item *

L<Net::SSH2>

=back

=head1 SYNOPSIS

 use Net::SSH2::Expect;
       
 my $exp = Net::SSH2::Expect->new($ssh2);
 $exp->spawn("passwd");
 $exp->expect($timeout, [
                           qr/Enter new UNIX password:/ => sub {
                                                              my ($exp, $line) = @_;
                                                              $exp->send($new_password);
                                                           },
                           qr/Retype new UNIX password:/ => sub {
                                                              my ($exp, $line) = @_;
                                                              $exp->send($new_password);
                                                           },
                           qr/passwd: password updated successfully/ => sub {
                                                                           my ($exp, $line) = @_;
                                                                           $exp->hard_close;
                                                                        },
                        ]);

=head1 CLASS METHODS

=cut

package Net::SSH2::Expect;

use strict;
use warnings;

our $VERSION = "0.1";

=over 4

=item new($ssh2)

Constructor: You need to parse an connected Net::SSH2 Object. 

=cut

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = {};

   bless($self, $proto);

   $self->{"__shell"} = $_[0]->channel();
   $self->{"__shell"}->pty("vt100");
   $self->{"__shell"}->shell;

   return $self;
}

sub shell {
   my ($self) = @_;
   return $self->{"__shell"};
}

=item spawn($command, @parameters)

Spawn $command with @parameters as parameters.

=cut
sub spawn {
   my ($self, $command, @parameters) = @_;

   my $cmd = "$command " . join(" ", @parameters);
   $self->shell->write($cmd . "\n");
}

=item soft_close()

Currently only an alias to hard_close();

=cut

sub soft_close {
   my ($self) = @_;
   $self->hard_close;
}

=item hard_close();

Stops the execution of the process.

=cut

sub hard_close {
   my ($self) = @_;
   die;
}

=item expect($timeout, @match_patters)

This method controls the execution of your process.

=cut

sub expect {
   my ($self, $timeout, @match_patterns) = @_;

   eval {
      local $SIG{'ALRM'} = sub { die; };
      alarm $timeout;

      my $line = "";
      while(1) {
         my $buf;
         $self->shell->read($buf, 1);
         if($self->_check_patterns($line, @match_patterns)) {
            $line = "";
            alarm $timeout;
            next;
         }
         $line .= $buf;
      }
   };
}

=item send($string)

Send a string to the running command.

=cut

sub send {
   my ($self, $str) = @_;
   $self->shell->write($str);
}

sub _check_patterns {
   my ($self, $line, @match_patterns) = @_;

   for my $pattern (@match_patterns) {
      if($line =~ $pattern->[0]) {
         my $code = $pattern->[1];
         &$code($self, $line);
         return 1;
      }
   }
}

=back

=cut

1;

